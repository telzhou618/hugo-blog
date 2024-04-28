# 我的博客项目

## 运行
```shell
hugo server # 仅渲染非draft的文章
hugo server -D #渲染文章包含配置了 draft:true 的内容
```

## 新建文章
```shell
hugo new posts/my-first-posts.md
```

## 编译
```shell
hugo -D # 编译生成静态博客到 public目录
```

## 样式
paper主题，因为默认的生成的页面太窄，需要修改css样式变宽一点。 修改 themes/paper/assets/main.css,修改内容如下,max-width修改为想要的值，默认值为48rem。
```css
.max-w-3xl {
  max-width: 56rem;
}
```

## 部署
发布到gitpage,在public目录下执行下面命令。
```shell
cd public
# initialize new git repository
git init

# add /public directory to our .gitignore file
echo "/public" >> .gitignore

# commit and push code to master branch
git add .
git commit -m "Updated"
git remote add origin https://github.com/telzhou618/telzhou618.github.io.git
git push -u origin main
```