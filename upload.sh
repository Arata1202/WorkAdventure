cd map-starter-kit-master

rm -rf dist && \
rm -rf map && \
rm dist.zip &&\
rm map.zip

npm run build
mv dist map
zip -r map.zip map

npm run upload
