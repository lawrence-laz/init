# init
Create custom project templates with ease.

## 📦 Set Up
1. Build from source:
```sh
git clone --depth 1 https://github.com/lawrence-laz/init && cd init && zig build --release=safe
```
2. Create your template configuration:
```sh
mkdir -p config/templates/your-template-name
```
2.1. Create template directory structure and files, for example:
```
config/templates/your-template-name
|- src/
|   |- main.zig
|- build.zig
|- build.zig.zon
```
3. Add an alias to your shell config:
```sh
alias init="/path/to/init/zig-out/bin/init -c '/path/to/init/config/'"
```

## 🔨 Use
```sh
mkdir my-project && cd my-project
init your-template-name
```
