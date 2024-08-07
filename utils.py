# utils.py
import os
import re
import requests
import pandas as pd
import ast
from geopy.distance import geodesic
from dotenv import load_dotenv

load_dotenv()

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
    road_address, address = None, None
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
                address = f"{area1} {area2} {area3} {number1}-{number2}" if number2 else f"{area1} {area2} {area3} {number1}"
    return road_address if road_address else address

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
            return {'lat': data['addresses'][0]['y'], 'lng': data['addresses'][0]['x']}
        else:
            return {'lat': None, 'lng': None}
    except (IndexError, KeyError, requests.exceptions.RequestException):
        return {'lat': None, 'lng': None}

def extract_location(question):
    location_pattern = re.compile(r'([\w\s]+(?:동|구|시|읍|면|리|로|길|아파트|빌딩|건물|\d+가길)(?:,?\s?[\w\s]*구,?\s?[\w\s]*시)?)')
    match = location_pattern.search(question)
    return match.group(1).strip() if match else None

def calculate_epdo(df):
    df['EPDO_cnt'] = 12 * df['dth_dnv_cnt'] + 6 * df['se_dnv_cnt'] + 3 * df['sl_dnv_cnt']
    for i in range(1, 7):
        df[f'EPDO_cnt_{i}'] = 12 * df[f'dth_dnv_cnt_{i}'] + 6 * df[f'se_dnv_cnt_{i}'] + 3 * df[f'sl_dnv_cnt_{i}']
    return df

def add_markers(mymap, filtered_df):
    for idx, row in filtered_df.iterrows():
        folium.Marker(location=[row['y'], row['x']], popup=f"Center EPDO: {row['EPDO_cnt']}").add_to(mymap)
        neighbours_centroids = ast.literal_eval(row['neighbours_centroids'])
        for i in range(1, 7):
            neighbour_col = f'EPDO_cnt_{i}'
            neighbour_coords = neighbours_centroids[i-1]
            folium.Marker(location=neighbour_coords, popup=f"Neighbor {i} EPDO: {row[neighbour_col]}", icon=folium.Icon(color='green')).add_to(mymap)

def create_base_map(center_lat=None, center_lng=None, zoom_start=12, radius_km=None):
    statistics = pd.read_csv('./data_set/final_new.csv')
    machine_learning = pd.read_csv('./data_set/to_check.csv')
    statistics.sort_values(by=['pred_EPDO'], inplace=True, ascending=False)
    
    pleasure = pd.read_csv('./data_set/pleasure_xy.csv').dropna()
    accident = pd.read_csv('./data_set/accident_xy.csv').dropna()
    silver = pd.read_csv('./data_set/silver_xy.csv').dropna()

    if center_lat is not None and center_lng is not None and radius_km is not None:
        def within_radius(row):
            return geodesic((center_lat, center_lng), (row['y'], row['x'])).km <= radius_km
        statistics = statistics[statistics.apply(within_radius, axis=1)]
        machine_learning = machine_learning[machine_learning.apply(within_radius, axis=1)]
        pleasure = pleasure[pleasure.apply(lambda row: geodesic((center_lat, center_lng), (row['Y'], row['X'])).km <= radius_km, axis=1)]
        accident = accident[accident.apply(lambda row: geodesic((center_lat, center_lng), (row['Y'], row['X'])).km <= radius_km, axis=1)]
        silver = silver[silver.apply(lambda row: geodesic((center_lat, center_lng), (row['Y'], row['X'])).km <= radius_km, axis=1)]
    
    init_point_stat_x = statistics['x'].values
    init_point_stat_y = statistics['y'].values
    init_point_ml_x = machine_learning['x'].values
    init_point_ml_y = machine_learning['y'].values

    if center_lat is None or center_lng is None:
        center_lat, center_lng = init_point_stat_y[0], init_point_stat_x[0]
    
    m = folium.Map(location=[center_lat, center_lng], zoom_start=zoom_start)
    for i in range(len(statistics)):
        folium.CircleMarker(location=[init_point_stat_y[i], init_point_stat_x[i]], radius=10, color='red', fill=True).add_child(folium.Popup('stat')).add_to(m)
    
    for i in range(len(machine_learning)):
        folium.CircleMarker(location=[init_point_ml_y[i], init_point_ml_x[i]], radius=10, color='blue', fill=True).add_child(folium.Popup('ml')).add_to(m)
    
    for i in range(len(pleasure)):
        folium.CircleMarker(location=[pleasure['Y'].values[i], pleasure['X'].values[i]], radius=1, color='green', fill=True).add_child(folium.Popup('pleasure')).add_to(m)
    
    for i in range(len(accident)):
        folium.CircleMarker(location=[accident['Y'].values[i], accident['X'].values[i]], radius=10, color='black', fill=True).add_child(folium.Popup('accident')).add_to(m)
    
    for i in range(len(silver)):
        folium.CircleMarker(location=[silver['Y'].values[i], silver['X'].values[i]], radius=1, color='silver', fill=True).add_child(folium.Popup('silver')).add_to(m)

    return m

def get_location_info(row):
    info = {
        '사망자 수': row['dth_dnv_cnt'],
        '중상자 수': row['se_dnv_cnt'],
        '경상자 수': row['sl_dnv_cnt'],
        '신고된 부상자 수': row['wnd_dnv_cnt'],
        '버스 정류장 수': row['bus_station_cnt'],
        '교통 신호등 수': row['traffic_cnt'],
        '유흥 시설 수': row['pleasure_cnt'],
        '경찰서 수': row['seoul_police_cnt'],
        '공원 수': row['park_cnt'],
        '교차로 수': row['crossroad_cnt'],
        '도로(10m 이하) 수': row['도로10이하_cnt'],
        '도로(10m ~ 20m) 수': row['도로10_20_cnt'],
        '도로(20m ~ 30m) 수': row['도로20_30_cnt'],
        '도로(30m 이상) 수': row['도로30이상_cnt'],
        '노인 보호 구역 수': row['silver_cnt'],
        '횡단보도 수': row['crosswalk_cnt'],
        '도로 유형': row['도로종류'],
        '도로 기능': row['도로기능'],
        '도로 크기': row['도로규모'],
        '도로 폭': row['도로폭']
    }
    info_text = "\n".join([f"{key}: {value}" for key, value in info.items()])
    return info_text
