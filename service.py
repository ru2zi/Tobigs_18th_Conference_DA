# service.py
import streamlit as st
import pandas as pd
import folium
from streamlit_folium import folium_static
from langchain import OpenAI, LLMChain
from langchain.prompts import PromptTemplate
from langchain.memory import ConversationBufferWindowMemory
from streamlit_chat import message
import uuid
from utils import point_to_address, address_to_point, extract_location, create_base_map, get_location_info, calculate_epdo, add_markers
from dotenv import load_dotenv

load_dotenv()

OPENAI_API_KEY = os.getenv("OPENAI_API_KEY")

haengjeongdong_roadtype = pd.read_csv('./data_set/행정동_도로유형_주소.csv')
final_df = pd.read_csv('./data_set/final.csv')

merged_df = pd.merge(final_df, haengjeongdong_roadtype, how='outer', left_on='center_address', right_on='주소')
merged_df['center_address'] = merged_df['center_address'].combine_first(merged_df['주소'])
merged_df.drop(columns=['주소'], inplace=True)

llm = OpenAI(api_key=OPENAI_API_KEY)

template = """
너는 노인들이 안전하게 살 수 있도록 도와주는 투빅이야.
투빅이는 서울의 특정 지점에서 시설 현황, 도로 유형 등과 같은 정보를 제공하여 노인 사용자들을 위한 안전 구역을 파악할 수 있도록 도와줘.
사용자의 질문과 관련된 상세하고 정확한 정보를 제공해 줘.
답변은 반드시 데이터프레임에서 추출된 정보만을 기반으로 해야 해. 거짓말을 해서는 안돼.
질문에 답변할 때는 반드시 데이터프레임의 해당 행의 정보를 사용하여 일관된 형식으로 답변해야 해.
추가 정보가 필요하다면, 추가 질문을 하여 사용자가 필요한 모든 세부 사항을 얻을 수 있도록 해.
친절하고 실제 대화를 나누는 것처럼 안내해줘.

{history}
사람: {input}
AI:
"""

prompt = PromptTemplate(template=template, input_variables=["history", "input"])
memory = ConversationBufferWindowMemory(k=0, return_messages=False)
conversation = LLMChain(llm=llm, prompt=prompt, memory=memory, output_key="output")

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
        location_name = extract_location(question)
        if location_name:
            location_name = location_name.replace('서울특별시', '').strip()
            exact_match = merged_df[merged_df['center_address'].str.contains(location_name, na=False)]
            if not exact_match.empty:
                for index, row in exact_match.iterrows():
                    location_info = get_location_info(row)
                    response = conversation.predict(input=f"{location_name}의 상세 정보는 다음과 같습니다:\n{location_info}")
                    st.session_state.conversation.append({"role": "AI", "content": response, "type": "text"})
                    visualize_location(row, merged_df)
                    break
            else:
                location = address_to_point(location_name)
                if location['lat'] and location['lng']:
                    address_from_location = point_to_address(location['lat'], location['lng'])
                    exact_match = merged_df[merged_df['center_address'].str.contains(address_from_location, na=False)]
                    if not exact_match.empty:
                        for index, row in exact_match.iterrows():
                            location_info = get_location_info(row)
                            response = conversation.predict(input=f"{location_name}의 상세 정보는 다음과 같습니다:\n{location_info}")
                            st.session_state.conversation.append({"role": "AI", "content": response, "type": "text"})
                            visualize_location(row, merged_df, show_epdo=False)
                            break
                    else:
                        row = {
                            'center_address': location_name,
                            'x': location['lng'],
                            'y': location['lat'],
                            'neighbours_centroids': '[]'
                        }
                        response = conversation.predict(input=f"{location_name}의 좌표는 {location['lat']}, {location['lng']}입니다. 해당 지점을 지도에 표시합니다.")
                        st.session_state.conversation.append({"role": "AI", "content": response, "type": "text"})
                        visualize_location(row, pd.DataFrame([row]), show_epdo=False)
                else:
                    st.session_state.conversation.append({"role": "AI", "content": "해당 지명을 찾을 수 없습니다. 다른 지명을 입력해 주세요.", "type": "text"})
        else:
            st.session_state.conversation.append({"role": "AI", "content": "지명을 추출할 수 없습니다. 다시 시도해 주세요.", "type": "text"})

display_conversation()
st.markdown("<div style='height: 100px;'></div>", unsafe_allow_html=True)
