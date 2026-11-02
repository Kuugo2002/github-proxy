# GitHub 代理 · Cloudflare Workers

使用本目录的 [worker.js](./worker.js) 将请求转发到 `https://github.com`，适用于 GitHub 网站请求和仓库文件下载。无需自行维护服务器，也没有第三方运行依赖。

这是独立的 Workers 版本，不使用项目根目录的 `server.js`，也不读取 Node.js 版本的环境变量。

## 功能

- 请求和响应均采用流式转发，不将整个文件加载到内存。
- 保留请求方法、编码路径、查询参数、`Authorization` 和 `Range`，支持上传及分段下载。
- 固定通过 HTTPS 访问 GitHub，请求路径不能指定其他上游主机。
- 本地响应浏览器 CORS 预检，允许跨域调用；浏览器可读取 `Content-Length`、`Content-Range`、`Accept-Ranges`、`ETag` 和 `Location`。
- GitHub 同源重定向改写为代理地址；外部 CDN 的签名地址保持原样。
- 上游请求抛出异常时返回带 CORS 响应头的 `502`；上游正常返回的 HTTP 错误状态保持原样。

## 部署

### 通过 Cloudflare 控制台

1. 登录 [Cloudflare 控制台](https://dash.cloudflare.com/)，进入 **Workers & Pages**。
2. 创建一个 Worker，可先使用 Hello World 示例完成初次部署。
3. 打开该 Worker 的 **Edit code（编辑代码）**。
4. 用本目录 `worker.js` 的完整内容替换默认代码，保存并部署。
5. 使用控制台提供的 `https://<worker-name>.<subdomain>.workers.dev` 地址访问代理，也可以为 Worker 配置自己的域名。

当前脚本使用 `addEventListener('fetch', ...)` 的 Service Worker 格式，复制时应完整替换默认代码，不要将它嵌入默认的 `export default` 中。无需配置环境变量、KV 或其他绑定。

控制台操作入口如有调整，请参考 [Cloudflare 控制台部署文档](https://developers.cloudflare.com/workers/get-started/dashboard/)。

## 使用

将原始 GitHub URL 的域名替换为你的 Worker 域名，路径和查询参数保持不变：

```text
https://github.com/octocat/Hello-World
→ https://<worker-name>.<subdomain>.workers.dev/octocat/Hello-World
```

```bash
export GITHUB_PROXY='https://<worker-name>.<subdomain>.workers.dev'
curl "$GITHUB_PROXY/octocat/Hello-World"
curl -L -o repo.zip "$GITHUB_PROXY/octocat/Hello-World/archive/refs/heads/master.zip"
```

需要认证时，可通过 `Authorization` 请求头传入令牌。不要将令牌写入 `worker.js` 或提交到仓库中。跨域请求不支持 `credentials: 'include'` 的 Cookie 认证。

## 重定向与限制

- **外部 CDN 需要客户端能够直接访问。** Worker 不自动跟随重定向。GitHub 域内跳转继续经过代理，跳到其他域名时由客户端直接访问；命令行下载可使用 `curl -L`。浏览器下载还取决于 CDN 自身的 CORS 策略。
- 采用手动重定向，避免 Workers 将 `Authorization`、`Cookie` 等请求头自动转发给外部目标，详见 [Cloudflare Request 文档](https://developers.cloudflare.com/workers/runtime-apis/request/)。使用 curl 时不要为此添加会跨域转发凭证的 `--location-trusted`。
- GitHub API（`api.github.com`）和静态资源等独立域名不会自动经过代理。不改写网页 HTML、页面中的链接或 Cookie 域名，不能保证完整网页浏览功能。
- 没有实现应用层缓存、重试、自定义超时或代理访问认证。公开部署后，知道地址的人可以使用该代理；如需限制使用，应另行配置入口访问控制。
- 流式转发不会绕过 Cloudflare 的请求体大小、资源和套餐限制，具体以 [Workers 限制文档](https://developers.cloudflare.com/workers/platform/limits/) 为准。
- `502` 表示建立上游请求或获取响应时发生异常。响应开始后才发生的流传输错误会中断下载，不能再改为 `502`。

## 本地验证

在项目根目录运行测试：

```bash
npm test
```

当前仓库未包含自动化测试；部署后请在 Cloudflare 环境中验证。

## 许可证

采用项目的 [MIT 许可证](../LICENSE)。
