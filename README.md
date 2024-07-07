# init
Create custom project templates with ease.

## 📦 Install
1. Build from source:
```sh
git clone --depth 1 https://github.com/lawrence-laz/init && cd init && zig build --release=safe
```
2. Add an alias to your shell config:
```sh
alias init="/path/to/init/zig-out/bin/init -c '/path/to/init/config/'"
```

## 🔨 Create a template
1. Create a directory for your new template:
```sh
mkdir -p config/templates/your-template-name
```
2. Create template sub-directory structure and files, for example:
```
config/templates/your-template-name
|- src/
|   |- main.zig
|- build.zig
|- build.zig.zon
```

## 🎉 Use
```sh
mkdir my-project && cd my-project
init your-template-name
```

## Parameters
Templates can have parameters, which are surrounded by three underscores (ex. `___name___`) in file contents, file and directory names.
Then they can be used by calling `init` with `-p name=value`, for example:
```sh
init your-template-name -p name=my-project -p "description=My very own project."
```
