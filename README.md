# APISIX Custom Plugin Development Kit

A streamlined environment for developing, testing, and monitoring custom APISIX plugins using Docker and Busted.

## 🚀 Quick Start

### 1. Start the Environment
Bring up the APISIX gateway and its dependencies:
bash ./busix.sh up

### 2. Run Unit Tests
Execute tests using Busted. You can run a specific file or include coverage reports.
# Run a specific test
bash ./busix.sh run spec/toksig-auth_spec.lua
# Run with Coverage Report
bash ./busix.sh run spec/toksig-auth_spec.lua -c

### 3. Monitor Logs
bash ./busix.sh tail

### 4. Stop Environment
bash ./busix.sh down

## 📡 API Usage Examples

### 1. Authenticate via JWT Token
curl -i http://localhost:9080/get \
-H "Token: <your_jwt_token>"

### 2. Authenticate via Signature (Fallback)
curl -i http://localhost:9080/get \
  -H "username: user123" \
  -H "Timestamp: 1712481600" \
  -H "X-Signature: <calculated_signature>"