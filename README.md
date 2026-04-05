test api: curl -i http://localhost:9080/get
run unit tests: 
    - echo "alias busted-api6='bash \$(pwd)/run_test.sh'" >> ~/.zshrc && source ~/.zshrc
    - busted-api6 spec/custom-signature-authorizer_spec.lua
    - busted-api6 spec/custom-signature-authorizer_spec.lua -c