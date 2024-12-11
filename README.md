# Ztml: An alternative to html

An easy way to write your messy html code in a better way:

```c
#define:name:Rohan

#include:navbar:navbar.html

html

head
    title
        {Ztml}
    title end
head end

body
    // Component:
    %navbar
    div style="color:blue;"
        h1
            {Hello, How are you?}
            %name
        h1 end
    div end
body end

html end
```

# How to use Ztml?
**Run:**
```shell
git clone https://github.com/RohanVashisht1234/ztml
cd ztml
zig build-exe ./main.zig -O ReleaseFast  
```
### Run example:

```shell
./main -config=./example/main.config
```

Config file looks like:

```rs
// Input ztml file  =  Output ztml file
./example/index.ztml=./build/index.html
```

You can also do:

```shell
./main ./example/index.ztml ./output.html
```
### Featues:

- Helps code readibility
    - Gives you errors of mistakes that you might have made in your code. Such as:
      - Did you forget to add a } at the end of line 15?
      - Warning: Number of tags starting is greater than the number of tags ending.
      - Warning: Number of tags ending is greater than the number of starting tags.
    - Helps make reliable html
- Use variables
    - This will help you save a lot of time.
- Import components
    - This again saves a lot of time and increases readability.


### Todo:
- Add hot reload and a live server
- Add js support
- Add css support
