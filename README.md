# APISIX Custom Plugin Development Kit

A streamlined environment for developing, testing, and monitoring custom APISIX plugins using Docker and Busted.

## 🚀 Quick Start

### 1. Start the Environment
Bring up the APISIX gateway and its dependencies:
```
bash ./busix.sh up
```

### 2. Run Unit Tests
Execute tests using Busted. You can run a specific file or include coverage reports.
#### Run a specific test
```
bash ./busix.sh run spec/dump_spec.lua
```
#### Run with Coverage Report
```
bash ./busix.sh run spec/dump_spec.lua -c
```

### 3. Monitor Logs
```
bash ./busix.sh tail
```

### 4. Stop Environment
```
bash ./busix.sh down
```