# 我的博客项目

## 新建文章
```shell
hugo new posts/my-first-posts.md
```
## 运行
```shell
hugo server -D # -D 渲染文章配置了 draft: true 的内容
```

## 编译生成静态博客到 public目录
```shell
hugo -D 
```

## 修css样式
因为默认的主题 paper 生成的页面太窄，需要修改css样式变宽一点。
- 修改 themes/paper/assets/main.css,修改内容如下,max-width修改为想要的值，默认值为48rem。
```css
.max-w-3xl {
  max-width: 56rem;
}
```

## 写博客流程
写好编译后把 public 目录下的文件拷贝到另一个项目 telzhou618.github.io 在 push 上去即可。