# Ztml: An alternative to html

An easy way to write your messy html code in a better way:

```ztml
html

head
    title
        {Ztml}
    title end
head end

body
    div style="color:blue;"
        h1
            {Hello, How are you?}
        h1 end
    div end
body end

html end
```

Compiled:

```ht
<html>
<head>
<title>
Ztml
</title>
</head>
<body>
<div style="color:blue;">
<h1>
Hello, How are you?
</h1>
</div>
</body>
</html>
```

# How to use Ztml?
**Run:**
```shell
git clone https://github.com/RohanVashisht1234/ztml
cd ztml
zig build-exe ./main.zig -O ReleaseFast  
```
### To compile a Ztml file to html:

```shell
./main ./some.ztml ./output.html
```

### Featues:

- Helps code readibility
    - Gives you errors of mistakes that you might have made in your code. Such as:
      - Did you forget to add a } at the end of line 15?
      - Warning: Number of tags starting is greater than the number of tags ending.
      - Warning: Number of tags ending is greater than the number of starting tags.
    - Helps make reliable html


### Todo:
- Add hot reload and a live server
- Add js support
- Add css support
