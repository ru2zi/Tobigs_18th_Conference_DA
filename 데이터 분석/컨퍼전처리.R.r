# install.packages("readr")
# install.packages("readxl")
library(readr)
library(readxl)
library(dplyr)
library(stringr)
# install.packages("dplyr")

# 데이터 불러오가
#1 주민등록인구 - 노인 https://data.seoul.go.kr/dataList/10043/S/2/datasetView.do
raw_pop = read.csv("C:/Users/thdud/Downloads/주민등록인구(연령별_동별)_20240514140854.csv", header = FALSE)
head(raw_pop)

pop <- raw_pop %>% 
  select(읍면동 = V2, 주민등록인구 = V20) %>%
  slice(5:nrow(.)) %>% 
  mutate(주민등록인구 = as.numeric(주민등록인구)) %>%
  filter(읍면동 != '소계')
summary(pop)
dim(pop)

#2 주민등록인구 - 전체 https://data.seoul.go.kr/dataList/10043/S/2/datasetView.do
raw_pop65 = read.csv("C:/Users/thdud/Downloads/주민등록인구(연령별_동별)_20240514104545.csv", header = FALSE)
head(raw_pop65)

pop65 <- raw_pop65 %>% 
  select(읍면동 = V2, 계 = V3, 주민등록인구 = V4) %>% 
  slice(6:nrow(.)) %>%
  filter(str_detect(읍면동, "동$"), 계 == "계") %>%
  mutate(주민등록인구 = as.numeric(주민등록인구)) %>%
  select(읍면동, 주민등록인구) %>%
  filter(읍면동 != '소계')
summary(pop65)
dim(pop65)


#3 자동차 수 https://data.seoul.go.kr/dataList/OA-22245/F/1/datasetView.do
raw_car = read.csv("C:/Users/thdud/Downloads/서울시 행정동별 자동차 등록대수 현황.csv", header = FALSE, fileEncoding = "euc-kr")
head(raw_car)
raw_car = as.data.frame(raw_car)
raw_car$V2

car <- raw_car %>% 
  select(읍면동 = V2, 자동차수 = V4) %>% 
  filter(str_detect(읍면동, "동 $")) %>%
  mutate(자동차수 = as.numeric(자동차수)) %>%
  group_by(읍면동) %>%
  summarise(자동차수 = sum(자동차수, na.rm = TRUE))
car = as.data.frame(car)
car <- car %>% 
  mutate(읍면동 = str_replace(읍면동, "^.*?\\s", ""))%>%
  mutate(읍면동 = str_replace_all(읍면동, "\\s+", ""))
dim(car)


#4 뭐지 
raw_what <- read.csv("C:/Users/thdud/Downloads/201_DT_201003_A010006_20240514104352.csv", header = TRUE, quote="" )
head(raw_what)

#5 노인교실(구별) https://data.seoul.go.kr/dataList/10157/S/2/datasetView.do 
raw_class<- read.csv("C:/Users/thdud/Downloads/노인여가+복지시설(동별)_20240514105710.csv", header = FALSE)

class <- raw_class %>% 
  slice(5:nrow(.)) %>% 
  select(자치구 = V2, 노인교실수 = V7) %>% 
  mutate(노인교실수 = as.numeric(노인교실수))
summary(class)
dim(class)

#6 경로당(구별) https://data.seoul.go.kr/dataList/10157/S/2/datasetView.do
raw_sen <- read.csv("C:/Users/thdud/Downloads/노인여가+복지시설(동별)_20240514105710.csv", header = FALSE)
head(raw_sen)

sen <- raw_sen %>% 
  slice(5:nrow(.)) %>% 
  select(자치구 = V2, 경로당수 = V6) %>% 
  mutate(경로당수 = as.numeric(경로당수))
summary(sen)
dim(sen)

#7 노인 기초생활보장 수급권자 https://data.seoul.go.kr/dataList/10176/S/2/datasetView.do
raw_base65 = read.csv("C:/Users/thdud/Downloads/독거노인+현황(연령별_동별)_20240514105418.csv", header = FALSE)
head(raw_base65)
sum(is.na(raw_base65))
base65 <- raw_base65 %>% 
  select(읍면동 = V3, 수급권자수 = V7) %>% 
  slice(6:nrow(.)) %>%
  mutate(수급권자수 = replace(수급권자수, 수급권자수 == '-', '0')) %>% 
  mutate(수급권자수 = as.numeric(수급권자수)) %>%
  filter(읍면동 != '소계')
  
summary(base65)
dim(base65)
base65['읍면동']


#8 횡단보도 위치 https://data.seoul.go.kr/dataList/OA-21209/S/1/datasetView.do
raw_walk = read.csv("C:/Users/thdud/Downloads/서울시 대로변 횡단보도 위치정보 (1).csv", header = FALSE, fileEncoding = "euc-kr")
head(raw_walk)
colnames(raw_walk)
raw_walk = as.data.frame(raw_walk)

walk <- raw_walk %>%
  select(읍면동 = V14) %>%
  group_by(읍면동) %>%
  summarise(횡단보도수 = n())
summary(walk)
walk = as.data.frame(walk)
dim(walk)

#9 상위 계층 https://data.seoul.go.kr/dataList/OA-22226/F/1/datasetView.do
raw_top = read.csv("C:/Users/thdud/Downloads/서울시 차상위계층 동별 연령별 현황.csv", header = FALSE, fileEncoding = "euc-kr")
head(raw_top)
top <- raw_top %>% 
  filter(!grepl("구$", V3)) %>% 
  select(읍면동 = V3, 상위수급권자수 = V7) %>% 
  slice(2:nrow(.)) %>%
  group_by(읍면동) %>%
  summarise(상위수급권자수 = sum(as.numeric(상위수급권자수), na.rm = TRUE))
summary(top) 
dim(top)
top = as.data.frame(top)


## 면적 혹은 인구 수로 scaling 필요해 보이는 애들 있음

#10 의료기관 https://data.seoul.go.kr/dataList/10123/S/2/datasetView.do
med <- read.csv("C:/Users/thdud/Downloads/의료기관(동별)_20240514105056.csv", header = FALSE)
head(med)

med <- med %>%
  filter(V5 == "소계", V3 !="소계") %>%
  select(읍면동 = V3, 병원수 = V6) %>% 
  select(읍면동, 병원수) %>%
  mutate(병원수 = as.numeric(병원수))
summary(med)
dim(med) 


#11 범죄 발생 현황 - 자치구별 https://data.seoul.go.kr/dataList/316/S/2/datasetView.do
crime <- read.csv("C:/Users/thdud/Downloads/5대+범죄+발생현황_20240514110355.csv", header = FALSE)
head(crime,10)
crime <- crime %>%
  slice(6:nrow(.)) %>%
  select(자치구 = V2, 범죄수 = V3) %>% 
  mutate(범죄수 = as.numeric(범죄수))
summary(crime)
dim(crime)

#12 기초생활수급자(전체) https://data.seoul.go.kr/dataList/OA-22227/F/1/datasetView.do
base <- read.csv("C:/Users/thdud/Downloads/서울시 국민기초생활 수급자 동별 현황/서울특별시 국민기초생활 수급자 동별 현황_20210731_v1.csv", header = FALSE, fileEncoding = "euc-kr")
head(base)

base <- base %>%
  select(읍면동 = V3, 기초생활수 = V6) %>%  # 구별 주민등록인구 추출
  slice(2:nrow(.)) %>%
  filter(str_detect(읍면동, "동$")) %>% 
  mutate(기초생활수 = as.numeric(기초생활수)) %>%
  group_by(읍면동) %>%  # 읍면동 별로 그룹화
  summarise(기초생활수 = sum(기초생활수, na.rm = TRUE))
summary(base)
dim(base)
base = as.data.frame(base)

#13 어린이보호구역 https://data.seoul.go.kr/dataList/OA-2796/F/1/datasetView.do
child <- read.csv("C:/Users/thdud/Downloads/행정동별_어린이_보호구역_지정현황(2023_6기준)/서울시 행정동별 어린이 보호구역 지정 통계(2023. 6월말 기준).csv", header = FALSE, fileEncoding = "euc-kr")
head(child)
child <- child %>%
  slice(3:nrow(.)) %>%
  select(읍면동 = V2, 보호구역수 = V3) %>% 
  mutate(보호구역수 = as.numeric(보호구역수))
summary(child)
dim(child)

#14 cctv 수 - 자치구 https://data.seoul.go.kr/dataList/OA-21097/F/1/datasetView.do
cctv <- read_excel("C:/Users/thdud/Downloads/서울시 자치구 (범죄예방 수사용) CCTV 설치현황_231231.xlsx")
cctv <- as.data.frame(cctv)
head(cctv,10)
cctv <- cctv %>%
  slice(3:(n()-1)) %>% 
  select(자치구 = ...2, cctv수 = ...11) %>%
  mutate(cctv수 = as.numeric(cctv수))
summary(cctv)
dim(cctv)

#15 주차장 https://data.seoul.go.kr/dataList/DT201004O1000132008/S/2/datasetView.do
cars <- read.csv("C:/Users/thdud/Downloads/주차장(동별)(2008)_20240514105244.csv", header = FALSE)
head(cars,10)
cars <- cars %>%
  filter(V3 !="소계") %>%
  slice(8:nrow(.)) %>%
  select(읍면동 = V3, 주차장수 = V4) %>%
  mutate(주차장수 = replace(주차장수, 주차장수 == '-', '0')) %>% 
  mutate(주차장수 = as.numeric(주차장수))
summary(cars)
dim(cars)


#16 노인 의료복지 https://data.seoul.go.kr/dataList/OA-22198/F/1/datasetView.do
# 이거 도로명주소여서 음
wel <- read_excel("C:/Users/thdud/Downloads/서울시 노인의료복지시설현황.xlsx")
wel <- as.data.frame(wel)



#17 사업체/종사자 https://data.seoul.go.kr/dataList/DT201004C010034/S/2/datasetView.do
work <- read.csv("C:/Users/thdud/Downloads/사업체현황+종사자수(산업대분류별_성별_동별)_20240514104145.csv",  header = FALSE)
head(work)


work <- work %>% 
  select(읍면동 = V3, 사업체수 = V4, 종사자수 = V5) %>% 
  slice(6:nrow(.)) %>% 
  filter(읍면동 !="소계") %>%
  mutate(사업체수 = as.numeric(사업체수), 종사자수 = as.numeric(종사자수))
summary(work)
dim(work)

#18 공동주택/아파트 https://data.seoul.go.kr/dataList/OA-15818/S/1/datasetView.do
apt <- read.csv("C:/Users/thdud/Downloads/서울시 공동주택 아파트 정보 (1).csv", header = FALSE, fileEncoding = "euc-kr")
head(apt)
apt <- apt %>% 
  select(읍면동 = V8) %>% 
  slice(2:nrow(.)) %>%
  group_by(읍면동) %>% 
  summarise(아파트수 = n())

summary(apt)  
dim(apt)
apt = as.data.frame(apt)

#19 시장현황 https://data.seoul.go.kr/dataList/10225/S/2/datasetView.do
mark <- read.csv("C:/Users/thdud/Downloads/시장현황_20240514134014.csv", header = FALSE)
head(mark)
mark <- mark %>% 
  select(읍면동 = V3, 시장수 = V4) %>% 
  slice(7:nrow(.)) %>%
  mutate(시장수 = replace(시장수, 시장수 == '-', '0')) %>% 
  mutate(시장수 = as.numeric(시장수))
summary(mark)
dim(mark)

#19 면적(구성비) - https://data.seoul.go.kr/dataList/10112/S/2/datasetView.do
area <- read.csv("C:/Users/thdud/Downloads/행정구역(동별)_20240514133826.csv", header = FALSE)
head(area)
area <- area %>% 
  slice(6:nrow(.)) %>%
  select(읍면동 = V3, 면적 = V4) %>% 
  filter(읍면동 !="소계") %>%
  mutate(면적 = as.numeric(면적))
summary(area)
dim(area)

#19 자전거 교통사고 - 자치구별 https://data.seoul.go.kr/dataList/10783/S/2/datasetView.do
bic <- read.csv("C:/Users/thdud/Downloads/자전거+교통사고_20240514133559.csv", header = FALSE)
head(bic,10)
bic <- bic %>% 
  slice(5:nrow(.)) %>%
  select(자치구 = V2, 자전거사고수 = V4) %>%
  mutate(자전거사고수 = as.numeric(as.character(자전거사고수))) %>%
  group_by(자치구) %>%
  summarise(자전거사고수 = sum(자전거사고수, na.rm = TRUE))
summary(bic)
dim(bic)

#19 노인 교통사고 - 자치구별 https://data.seoul.go.kr/dataList/10777/S/2/datasetView.do
acc <- read.csv("C:/Users/thdud/Downloads/노인+교통사고+현황_20240514133541.csv", header = FALSE)
head(acc,10)

acc <- acc %>% 
  slice(5:nrow(.)) %>%
  select(자치구 = V2, 노인교통사고 = V3) %>%
  mutate(노인교통사고 = as.numeric(노인교통사고))
summary(acc)
dim(acc)

#19 보행자 교통사고(부상자수) - 자치구별 https://data.seoul.go.kr/dataList/324/S/2/datasetView.do
accw <- read.csv("C:/Users/thdud/Downloads/보행자+사고현황_20240514133614.csv", header = FALSE)
head(accw,10)

accw <-accw %>% 
  slice(6:nrow(.)) %>%
  select(자치구 = V2, 보행자교통사고수 = V4) %>%
  mutate(보행자교통사고수 = as.numeric(보행자교통사고수))
summary(accw)
dim(accw)



























### 읍면동 데이터 합칠게
dong_data <- full_join(pop, pop65, by = "읍면동") %>% 
  full_join(car, by = "읍면동") %>% 
  full_join(base65, by = "읍면동") %>% 
  full_join(work, by = "읍면동") %>% 
  full_join(top, by = "읍면동") %>% 
  full_join(med, by = "읍면동") %>% 
  full_join(base, by = "읍면동") %>% 
  full_join(child, by = "읍면동") %>% 
  full_join(cars, by = "읍면동") %>% 
  full_join(walk, by = "읍면동") %>% 
  full_join(apt, by = "읍면동") %>% 
  full_join(mark, by = "읍면동") %>% 
  full_join(area, by = "읍면동")
dong_data
dim(dong_data)
missing_rows <- dong_data[rowSums(is.na(dong_data)) >= 14, ]


gu_data <- full_join(class, sen, by = "자치구") %>% 
  full_join(crime, by = "자치구") %>% 
  full_join(cctv, by = "자치구") %>% 
  full_join(bic, by = "자치구") %>% 
  full_join(acc, by = "자치구") %>% 
  full_join(accw, by = "자치구")
gu_data
dim(gu_data)

# 동별 데이터 박스 플롯
library(ggplot2)
plot1 = ggplot(data = dong_data, aes(x = "", y = dong_data[, 2])) +
  geom_boxplot(fill = "blue", color = "black") +  
  labs(title = "노인인구", y = "노인인구") +
  theme_minimal()
stat_boxplot()

plot2=ggplot(data = dong_data, aes(x = "", y = dong_data[, 3])) +
  geom_boxplot(fill = "blue", color = "black") + 
  labs(title = "주민등록인구", y = "주민등록인구") +
  theme_minimal()

plot3=ggplot(data = dong_data, aes(x = "", y = dong_data[, 4])) +
  geom_boxplot(fill = "blue", color = "black") + 
  labs(title = "자동차수", y = "자동차수") +
  theme_minimal()

plot4=ggplot(data = dong_data, aes(x = "", y = dong_data[, 5])) +
  geom_boxplot(fill = "blue", color = "black") +
  labs(title = "수급권자수", y = "수급권자수") +
  theme_minimal()

plot5=ggplot(data = dong_data, aes(x = "", y = dong_data[, 6])) +
  geom_boxplot(fill = "blue", color = "black") +  
  labs(title = "사업체수", y = "사업체수") +
  theme_minimal()

plot6=ggplot(data = dong_data, aes(x = "", y = dong_data[, 7])) +
  geom_boxplot(fill = "blue", color = "black") +  
  labs(title = "종사자수", y = "종사자수") +
  theme_minimal()

plot7=ggplot(data = dong_data, aes(x = "", y = dong_data[, 8])) +
  geom_boxplot(fill = "blue", color = "black") +  
  labs(title = "상위수급권자수", y = "상위수급권자수") +
  theme_minimal()

plot8=ggplot(data = dong_data, aes(x = "", y = dong_data[, 9])) +
  geom_boxplot(fill = "blue", color = "black") +  
  labs(title = "병원수", y = "병원수") +
  theme_minimal()

plot9=ggplot(data = dong_data, aes(x = "", y = dong_data[, 10])) +
  geom_boxplot(fill = "blue", color = "black") + 
  labs(title = "기초생활수", y = "기초생활수") +
  theme_minimal()

plot10=ggplot(data = dong_data, aes(x = "", y = dong_data[, 11])) +
  geom_boxplot(fill = "blue", color = "black") + 
  labs(title = "보호구역수", y = "보호구역수") +
  theme_minimal()

# 너무 이산적...
plot11=ggplot(data = dong_data, aes(x = "", y = dong_data[, 12])) +
  geom_boxplot(fill = "blue", color = "black") +
  labs(title = "주차장수", y = "주차장수") +
  theme_minimal()

plot12=ggplot(data = dong_data, aes(x = "", y = dong_data[, 13])) +
  geom_boxplot(fill = "blue", color = "black") + 
  labs(title = "횡단보도수", y = "횡단보도수") +
  theme_minimal()

plot13=ggplot(data = dong_data, aes(x = "", y = dong_data[, 14])) +
  geom_boxplot(fill = "blue", color = "black") +  
  labs(title = "아파트수", y = "아파트수") +
  theme_minimal()

# 얘도 박스 크기 너무 작네
plot14=ggplot(data = dong_data, aes(x = "", y = dong_data[, 15])) +
  geom_boxplot(fill = "blue", color = "black") + 
  labs(title = "시장수", y = "시장수") +
  theme_minimal()

plot15=ggplot(data = dong_data, aes(x = "", y = dong_data[, 16])) +
  geom_boxplot(fill = "blue", color = "black") + 
  labs(title = "면적", y = "면적") +
  theme_minimal()

library(gridExtra)

grid.arrange(plot1, plot2, plot3, plot4, plot5, plot6, plot7, plot8, ncol = 4)
grid.arrange(plot9, plot10, plot11, plot12, plot13, plot14, plot15, ncol = 4)


#구별 데이터 박스 플롯
plot_1 = ggplot(data = gu_data, aes(x = "", y = gu_data[, 2])) +
  geom_boxplot(fill = "blue", color = "black") + 
  labs(title = "노인교실수", y = "노인교실수") +
  theme_minimal()

plot_2=ggplot(data = gu_data, aes(x = "", y = gu_data[, 3])) +
  geom_boxplot(fill = "blue", color = "black") +  
  labs(title = "경로당수", y = "경로당수") +
  theme_minimal()

plot_3=ggplot(data = gu_data, aes(x = "", y = gu_data[, 4])) +
  geom_boxplot(fill = "blue", color = "black") +  
  labs(title = "범죄수", y = "범죄수") +
  theme_minimal()

plot_4=ggplot(data = gu_data, aes(x = "", y = gu_data[, 5])) +
  geom_boxplot(fill = "blue", color = "black") + 
  labs(title = "cctv수", y = "cctv수") +
  theme_minimal()

plot_5=ggplot(data = gu_data, aes(x = "", y = gu_data[, 6])) +
  geom_boxplot(fill = "blue", color = "black") + 
  labs(title = "자전거사고수", y = "자전거사고수") +
  theme_minimal()

plot_6=ggplot(data = gu_data, aes(x = "", y = gu_data[, 7])) +
  geom_boxplot(fill = "blue", color = "black") +  
  labs(title = "노인교통사고", y = "노인교통사고") +
  theme_minimal()

plot_7=ggplot(data = gu_data, aes(x = "", y = gu_data[, 8])) +
  geom_boxplot(fill = "blue", color = "black") + 
  labs(title = "보행자교통사고수", y = "보행자교통사고수") +
  theme_minimal()

grid.arrange(plot_1, plot_2, plot_3, plot_4, plot_5, plot_6, plot_7, ncol = 4)


# 구별 데이터 지도 시각화

library(sf)
raw_map <- st_read("C:/Users/thdud/Downloads/TL_SCCO_SIG (1).json", quiet = TRUE)

seoul_map <- raw_map[140:164, ]
seoul_map_subset <- seoul_map[, c("geometry", "SIG_CD")]

pic11=ggplot() +
  geom_sf(data = seoul_map_subset, aes(fill = gu_data[, 2])) +
  scale_fill_gradient(low = "white", high = "blue") +
  labs(title = "서울시 노인 교실 수", fill = "노인교실수") +
  theme_minimal()

#자동차 수 지도 시각화
pic21=ggplot() +
  geom_sf(data = seoul_map_subset, aes(fill = gu_data[, 3])) +
  scale_fill_gradient(low = "white", high = "blue") +
  labs(title = "서울시 경로당 수", fill = "경로당수") +
  theme_minimal()

#수소차 수 지도 시각화
pic31=ggplot() +
  geom_sf(data = seoul_map_subset, aes(fill = gu_data[, 4])) +
  scale_fill_gradient(low = "white", high = "blue") +
  labs(title = "서울시 범죄 수", fill = "범죄수") +
  theme_minimal()

#수소충전소 개소수 지도 시각화
pic41=ggplot() +
  geom_sf(data = seoul_map_subset, aes(fill = gu_data[, 5])) +
  scale_fill_gradient(low = "white", high = "blue") +
  labs(title = "서울시 cctv 수", fill = "cctv수") +
  theme_minimal()

#교통량 지도 시긱화
pic51=ggplot() +
  geom_sf(data = seoul_map_subset, aes(fill = gu_data[, 6])) +
  scale_fill_gradient(low = "white", high = "blue") +
  labs(title = "서울시 자전거 사고 수", fill = "자전거사고수") +
  theme_minimal()

#사업체 수 지도 시각화
pic61=ggplot() +
  geom_sf(data = seoul_map_subset, aes(fill = as.numeric(gu_data[, 7]))) +
  scale_fill_gradient(low = "white", high = "blue") +
  labs(title = "서울시 노인 교통사고 수", fill = "노인교통사고수") +
  theme_minimal()

pic71=ggplot() +
  geom_sf(data = seoul_map_subset, aes(fill = as.numeric(gu_data[, 8]))) +
  scale_fill_gradient(low = "white", high = "blue") +
  labs(title = "서울시 보행자 교통사고 수", fill = "보행자교통사고수") +
  theme_minimal()

library(gridExtra)

grid.arrange(pic11, pic21, pic31, pic41, pic51, pic61, pic71, ncol = 4)

















#-------------------------------------------

#01 서울 법정동 행정동 맵핑 데이터
raw_mapping <- read.csv("C:/Users/gr323/OneDrive/Desktop/행정동 법정동 관련 데이터/KIKmix.20230703.csv", header = TRUE)
#02 서울 각 단위의 행정동 기준 코드
raw_ADSTRD_CD <- read.csv("C:/Users/gr323/OneDrive/Desktop/행정동 법정동 관련 데이터/한국행정구역분류_2023.7.1.기준_20230703011207.csv", header = FALSE)
#03 Shape File
raw_map <- st_read("C:/Users/gr323/OneDrive/Desktop/TL_SCCO_SIG.json", quiet = TRUE)



#install.packages("ggmap")
library(ggmap)
#install.packages("ggplot2")
library(ggplot2)
#install.packages("raster")
library(raster)
#install.packages("rgeos")
library(rgeos)
#install.packages("maptools")
library(maptools)
#install.packages("rgdal")
library(rgdal)



#"C:\Users\thdud\Downloads\emd_20230729\emd.shp" -> 동별시각화에쓸거임
install.packages("sf")
library(sf)
map = readOGR("C:/Users/thdud/Downloads/emd_20230729/emd.shp",encoding = "EUC-KR")


## 축척을 고정한다. 
ggplot(data = df_map, aes(x = long, y = lat, group = group)) + 
  geom_polygon(fill='white', color='black') + 
  coord_quickmap()


## 지도의 기본데이터만 추출한다. 
df_map_info <- map@data

## df_map과 df_map_info의 id를 매칭한다.
df_map_info$id <- 1:nrow(df_map_info) - 1

## 시도 구분 id를 뽑아낸다. 
df_map_info$sido <- as.numeric(substr(df_map_info$EMD_CD, start = 1, stop = 2))

head(df_map_info)
head(df_map)
## 서울을 추출해 보자
id_sido <- df_map_info[df_map_info$sido == 11, "id"]

id_sido

## 서울만 추출하여 뽑아낸다. 
df_map2 <- df_map[df_map$id %in% id_sido, ]
df_map2_info <- df_map_info[df_map_info$id %in% id_sido, ]

summary(df_map2_info)
head(df_map2_info)
head(df_map2)

#서울 동 시각화 틀
ggplot(data = df_map2,
       aes(x = long, y = lat, 
           group = group)) + 
  geom_polygon(color = "black", fill = "white") + 
  theme(legend.position = "none")



mapping_data <- as.data.frame(df_map2_info) %>% select(EMD_CD, EMD_KOR_NM)
## 서울특별시의 읍면동별 인구를 시각화해 보자. 
df_map2_pop <- merge(df_map2, df_map2_temp, by = "id")
df_map2
ggplot(data = df_map2_pop,
       aes(x = long, y = lat, group = group, fill = pop)) + 
  geom_polygon(color = "black") 



