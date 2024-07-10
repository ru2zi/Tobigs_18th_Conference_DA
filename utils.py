import requests
import re
import os
import ast
import folium
from dotenv import load_dotenv
import streamlit as st

# Load .env file
load_dotenv()

# Get API keys from .env file
NAVER_CLIENT_ID = os.getenv("NAVER_CLIENT_ID")
NAVER_CLIENT_SECRET = os.getenv("NAVER_CLIENT_SECRET")
GEOCODE_CLIENT_ID = os.getenv("GEOCODE_CLIENT_ID")
GEOCODE_CLIENT_SECRET = os.getenv("GEOCODE_CLIENT_SECRET")

def point_to_address(latitude, longitude):
    url = f"https://naveropenapi.apigw.ntruss.com/map-reversegeocode/v2/gc?request=coordsToaddr&coords={longitude},{latitude}&sourcecrs=epsg:4326&output=json&orders=legalcode,admcode,addr,roadaddr"
    headers = {
        "X-NCP-APIGW-API-KEY-ID": NAVER_CLIENT_ID,
        "X-NCP-APIGW-API-KEY": NAVER_CLIENT_SECRET
    }

    response = requests.get(url, headers=headers)
    data = response.json()

    road_address = None
    address = None

    if 'results' in data:
        for result in data['results']:
            if result['name'] == 'roadaddr':
                road_address = result['region']['area1']['name'] + ' ' + result['region']['area2']['name'] + ' ' + result['region']['area3']['name']
                break
            elif result['name'] == 'addr':
                area1 = result['region']['area1']['name']
                area2 = result['region']['area2']['name']
                area3 = result['region']['area3']['name']
                number1 = result['land']['number1']
                number2 = result['land']['number2']
                if number2:
                    address = f"{area1} {area2} {area3} {number1}-{number2}"
                else:
                    address = f"{area1} {area2} {area3} {number1}"

    if road_address:
        return road_address
    else:
        return address

def address_to_point(address):
    url = f'https://naveropenapi.apigw.ntruss.com/map-geocode/v2/geocode?query={address}'
    headers = {
        'X-NCP-APIGW-API-KEY-ID': GEOCODE_CLIENT_ID,
        'X-NCP-APIGW-API-KEY': GEOCODE_CLIENT_SECRET
    }

    try:
        response = requests.get(url, headers=headers)
        response.raise_for_status()
        data = response.json()
        if data['status'] == 'OK':
            return {
                'lat': data['addresses'][0]['y'],
                'lng': data['addresses'][0]['x']
            }
        else:
            return {'lat': None, 'lng': None}
    except (IndexError, KeyError):
        return {'lat': None, 'lng': None}
    except requests.exceptions.RequestException as e:
        print(f"Error: {e}")
        return {'lat': None, 'lng': None}

def extract_location(question):
    location_pattern = re.compile(
        r'([\w\s]+(?:동|구|시|읍|면|리|로|길|아파트|빌딩|건물|\d+가길)(?:,?\s?[\w\s]*구,?\s?[\w\s]*시)?)'
    )
    match = location_pattern.search(question)
    if match:
        return match.group(1).strip()
    return None

def calculate_epdo(df):
    df['EPDO_cnt'] = 12 * df['dth_dnv_cnt'] + 6 * df['se_dnv_cnt'] + 3 * df['sl_dnv_cnt']
    for i in range(1, 7):
        df[f'EPDO_cnt_{i}'] = 12 * df[f'dth_dnv_cnt_{i}'] + 6 * df[f'se_dnv_cnt_{i}'] + 3 * df[f'sl_dnv_cnt_{i}']
    return df

def add_markers(mymap, filtered_df):
    for idx, row in filtered_df.iterrows():
        folium.Marker(location=[row['y'], row['x']], 
                      popup=f"Center EPDO: {row['EPDO_cnt']}").add_to(mymap)
        
        neighbours_centroids = ast.literal_eval(row['neighbours_centroids'])
        for i in range(1, 7):
            neighbour_col = f'EPDO_cnt_{i}'
            neighbour_coords = neighbours_centroids[i-1]
            folium.Marker(location=neighbour_coords, 
                          popup=f"Neighbor {i} EPDO: {row[neighbour_col]}", 
                          icon=folium.Icon(color='green')).add_to(mymap)

def visualize_location(row, filtered_df, show_epdo=True):
    st.session_state.conversation.append({"role": "AI", "content": f"{row['center_address']}에 대한 정보를 시각화합니다...", "type": "text"})
    m = folium.Map(location=[row['y'], row['x']], zoom_start=15)
    folium.Marker([row['y'], row['x']], popup=row['center_address']).add_to(m)
    if show_epdo:
        calculate_epdo(filtered_df)
        filtered_location_df = filtered_df[filtered_df['center_address'] == row['center_address']]
        if not filtered_location_df.empty:
            add_markers(m, filtered_location_df)
        else:
            st.session_state.conversation.append({"role": "AI", "content": "해당 지점에 대한 구체적인 위험 정보를 찾을 수 없습니다.", "type": "text"})
    st.session_state.conversation.append({"role": "AI", "content": m, "type": "map"})
