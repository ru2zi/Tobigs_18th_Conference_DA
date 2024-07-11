import streamlit as st
import pandas as pd
import geopandas as gpd
import folium
from streamlit_folium import folium_static
from langchain import OpenAI, LLMChain
from langchain.prompts import PromptTemplate
from langchain.memory import ConversationBufferMemory
from fuzzywuzzy import process
from streamlit_chat import message
import uuid
from langchain.memory import ConversationBufferWindowMemory
import ast
import os
from dotenv import load_dotenv
from utils import point_to_address, address_to_point, extract_location, calculate_epdo, add_markers, visualize_location, create_base_map

load_dotenv()

NAVER_CLIENT_ID = os.getenv("NAVER_CLIENT_ID")
NAVER_CLIENT_SECRET = os.getenv("NAVER_CLIENT_SECRET")
GEOCODE_CLIENT_ID = os.getenv("GEOCODE_CLIENT_ID")
GEOCODE_CLIENT_SECRET = os.getenv("GEOCODE_CLIENT_SECRET")
OPENAI_API_KEY = os.getenv("OPENAI_API_KEY")

haengjeongdong_roadtype = pd.read_csv('./data_set/행정동_도로유형_주소.csv')
final_df = pd.read_csv('./data_set/final.csv')

merged_df = pd.merge(final_df, haengjeongdong_roadtype, how='outer', left_on='center_address', right_on='주소')
merged_df['center_address'] = merged_df['center_address'].combine_first(merged_df['주소'])

merged_df.drop(columns=['주소'], inplace=True)

# LangChain 설정
llm = OpenAI(api_key=OPENAI_API_KEY)

template = """
너는 노인들이 안전하게 살 수 있도록 도와주는 투빅이야.
투빅이는 서울의 특정 지점에서 시설 현황, 도로 유형 등과 같은 정보를 제공하여 노인 사용자들을 위한 안전 구역을 파악할 수 있도록 도와줘.
사용자의 질문과 관련된 상세하고 정확한 정보를 제공해 줘.
데이터프레임에서 추출된 정보만을 기반으로 답변해야 해. 거짓말을 해서는 안돼.
질문에 답변할 때는 반드시 데이터프레임의 해당 행의 정보를 사용하여 일관된 형식으로 답변해야 해.
추가 정보가 필요하다면, 추가 질문을 하여 사용자가 필요한 모든 세부 사항을 얻을 수 있도록 해.

{history}
사람: {input}
AI: 
"""

prompt = PromptTemplate(template=template, input_variables=["history", "input"])
memory = ConversationBufferWindowMemory(k=0, return_messages=False)

conversation = LLMChain(llm=llm, prompt=prompt, memory=memory, output_key="output")

# Streamlit UI 설정
st.title('경로당 아이들')
st.write("서울시의 특정 장소에 대해 검색해보고 해당 지역의 위험 구간을 확인해보세요.")

if 'conversation' not in st.session_state:
    st.session_state.conversation = []

def display_conversation():
    for i, chat in enumerate(st.session_state.conversation):
        if chat["role"] == "Human":
            message(chat["content"], is_user=True, key=f"human_{i}_{uuid.uuid4()}", avatar_style="adventurer")
        else:
            if chat["type"] == "text":
                message(chat["content"], key=f"ai_{i}_{uuid.uuid4()}", avatar_style="adventurer-neutral")
            elif chat["type"] == "map":
                folium_static(chat["content"])

question = st.chat_input("질문을 입력하세요:")

if question:
    with st.spinner("답변 생성 중이니 건들지 마세요..."):
        response = conversation.predict(input=question)
        st.session_state.conversation.append({"role": "Human", "content": question, "type": "text"})
        st.session_state.conversation.append({"role": "AI", "content": response, "type": "text"})

        location_name = extract_location(question)
        if location_name:
            location_name = location_name.replace('서울특별시', '').strip()
            exact_match = merged_df[merged_df['center_address'].str.contains(location_name, na=False)]
            if not exact_match.empty:
                for index, row in exact_match.iterrows():
                    visualize_location(row, merged_df)
                    break
            else:
                location = address_to_point(location_name)
                if location['lat'] and location['lng']:
                    address_from_location = point_to_address(location['lat'], location['lng'])
                    exact_match = merged_df[merged_df['center_address'].str.contains(address_from_location, na=False)]
                    if not exact_match.empty:
                        for index, row in exact_match.iterrows():
                            visualize_location(row, merged_df, show_epdo=False)
                            break
                    else:
                        row = {
                            'center_address': location_name,
                            'x': location['lng'],
                            'y': location['lat'],
                            'neighbours_centroids': '[]'
                        }
                        visualize_location(row, pd.DataFrame([row]), show_epdo=False)
                else:
                    row = {
                        'center_address': location_name,
                        'x': location['lng'],
                        'y': location['lat'],
                        'neighbours_centroids': '[]'
                    }
                    base_map = create_base_map(location['lat'], location['lng'], zoom_start=15, radius_km=1)
                    st.session_state.conversation.append({"role": "AI", "content": base_map, "type": "map"})
                    st.session_state.conversation.append({"role": "AI", "content": "해당 지명을 찾을 수 없습니다. 다른 지명을 입력해 주세요.", "type": "text"})
        else:
            st.session_state.conversation.append({"role": "AI", "content": "지명을 추출할 수 없습니다. 다시 시도해 주세요.", "type": "text"})

display_conversation()
st.markdown("<div style='height: 100px;'></div>", unsafe_allow_html=True)
