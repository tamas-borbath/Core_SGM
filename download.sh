cd JAO
# Latest Static Grid Model
url="https://www.jao.eu/sites/default/files/2023-03/20230301_Core%20Static%20Grid%20Model_3.xlsx"
output_file="SGM.xlsx"
curl -L $url -o $output_file
# Latest Static Grid Map
url="https://www.jao.eu/sites/default/files/2023-03/20230224_Core%20Static%20Grid%20Model%20Map_3.zip"
output_file="map.zip"
curl -L $url -o $output_file
unzip $output_file
rm $output_file
for file in *.zip; do unzip "$file" -d "./Map/"; done
rm *.zip