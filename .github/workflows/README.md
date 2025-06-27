# GitHub Actions for Docker Build

简单的GitHub Action工作流，用于自动构建和推送ComfyUI Docker镜像。

## 工作流说明

### Build and Push Docker Images (`build-and-push.yml`)

**触发条件:**
- 推送到 `main` 或 `master` 分支
- 推送以 `v*` 开头的标签
- 手动触发

**功能:**
- 使用 `docker-bake.hcl` 构建Docker镜像
- 支持多种构建目标
- 自动推送到Docker Hub

**构建目标:**
- `default`: 构建默认目标 (cu128-py312)
- `all`: 构建所有变体
- 特定目标: cu124-py311-comm, cu124-py312-comm, cu128-py311-comm, cu128-py312-comm

## 设置要求

### GitHub Secrets

需要在GitHub仓库中配置以下secrets:

1. **`DOCKER_USERNAME`** - Docker Hub用户名
2. **`DOCKER_PASSWORD`** - Docker Hub密码或访问令牌

**添加secrets步骤:**
1. 进入GitHub仓库
2. 点击 Settings → Secrets and variables → Actions
3. 点击 "New repository secret"
4. 添加所需的secrets

## 使用方法

### 自动构建

1. **推送到main分支**: 构建默认镜像
2. **创建标签**: 构建所有镜像变体
   ```bash
   git tag v0.3.41-fastapi-v0.0.2
   git push origin v0.3.41-fastapi-v0.0.2
   ```

### 手动构建

1. 进入GitHub仓库的 **Actions** 标签页
2. 选择 **"Build and Push Docker Images"**
3. 点击 **"Run workflow"**
4. 选择构建目标 (default, all, 或特定目标)

## 镜像标签

构建的镜像使用以下标签格式:
- `useless1234567/comfyui:cu128-py312-v0.3.40-fastapi-v0.0.1`
- `useless1234567/comfyui:cu124-py311-v0.3.40-fastapi-v0.0.1`

## 故障排除

### 常见问题

1. **Docker Hub登录失败**
   - 检查 `DOCKER_USERNAME` 和 `DOCKER_PASSWORD` secrets是否正确设置
   - 验证Docker Hub凭据

2. **构建失败**
   - 检查Actions日志中的详细错误信息
   - 确保docker-bake.hcl配置正确
