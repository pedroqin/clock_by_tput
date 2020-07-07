## 目的
通过简易时钟的实现，熟悉tput各功能参数

## 实现
### 主要实现功能
- 时钟功能（字符画显示）
- 秒级进度显示
- 跟随窗口大小变化

### 主要实现代码
```shell
#!/bin/bash

whereami=`cd $(dirname $0);pwd`

# 使用已完成的脚本工具实现时间的字符画转换
Ascii_Signature_dir="$whereami/Ascii_Signature/"
Ascii_Signature="$Ascii_Signature_dir/ascii_signature.sh -n -s "
# source dictionary
. $Ascii_Signature_dir/font/doom

......

# 获取窗口大小
function terminal_size()
{ 
    terminal_cols="$(tput cols)"
    terminal_rows="$(tput lines)"
}

# 获取字符画大小
function ASCII_Art_size() 
{
    ......
}
# 显示时钟
function display_clock()
{
    ......
        # 光标位置控制
        tput cup $row $clock_col
    ......
}
# 初始化时钟
function init_clock()
{
    ......
    # 获取终端属性是否支持 bce
    if tput bce; then 
        clear
    else # Do it the hard way
        # 控制光标到开头左侧
        tput home
        echo -n "$blank_screen"
    fi
}

function display()
{
    ......
    init_clock

    while true; do
        # 控制光标到指定位置
        tput cup $clock_row $clock_col
        display_clock
        # 显示 秒 进度条背景
        tput cup $progress_row $progress_col
        echo -n ${FG_BLACK}
        echo -n "$second_bar"

        tput cup $progress_row $progress_col
        echo -n ${FG_WHITE}
        ......
        # 获取当前时间后刷新 秒 进度条前景
        while true;do
            # date +%S 秒数，00-59
            i=$(date +%S|bc)
            [ -z "$ii" ] && ii=$i
            # 秒数增加，输出白色 # 覆盖背景深色 #
            [ $i -gt $ii ] && echo -n "#"
            # 59之后归0，跳出while循环进行下次时钟显示
            [ $i -lt $ii ] && unset ii && break
            sleep $refresh_rate
            ii=$i
            # 获取 WINCH 信号后，停止当前显示（退出当前函数）
            [ $IF_WINCH -ne 0 ] && return
        done
    done 
}

# 接收到 SIGINT 信号后，关闭所有样式，恢复指针到正常状态，恢复屏幕内容
trap 'tput sgr0; tput cnorm; tput rmcup || clear; exit 0' SIGINT
# 接收到 WINCH （窗口大小变化）信号，将变量置1
trap 'IF_WINCH=1' WINCH

# 终端前景/背景颜色控制
BG_BLUE="$(tput setab 4)"
FG_BLACK="$(tput setaf 0)"
FG_WHITE="$(tput setaf 7)"

# 保存当前屏幕内容，隐藏指针
tput smcup; tput civis

# 主循环
ASCII_Art_size
while true; do
    start_flag=0
    IF_WINCH=0
    display
done

```
## 知识点
### 获取终端属性
|Capname|Description|
|:--|:--|
|longname|Full name of the terminal type|
|lines|Number of lines in the terminal|
|cols|Number of columns in the terminal|
|colors|Number of colors available|

### 控制光标
|Capname|Description|
|:--|:--|
|sc|Save the cursor position|
|rc|Restore the cursor position|
|home|Move the cursor to upper left corner (0,0)|
|cup `<row> <col>`|Move the cursor to position row, col|
|cud1|Move the cursor down 1 line|
|cuu1|Move the cursor up 1 line|
|civis|Set to cursor to be invisible|
|cnorm|Set the cursor to its normal state|

### 文本样式
|Capname|Description|
|:--|:--|
|bold|Start bold text|
|smul|Start underlined text|
|rmul|End underlined text|
|rev|Start reverse video|
|blink|Start blinking text|
|invis|Start invisible text|
|smso|Start "standout" mode|
|rmso|End "standout" mode|
|sgr0|Turn off all attributes|
|setaf `<value>`|Set foreground color|
|setab `<value>`|Set background color|

### 文本颜色
|Value|Color|
|:--|:--|
|0|Black|
|1|Red|
|2|Green|
|3|Yellow|
|4|Blue|
|5|Magenta|
|6|Cyan|
|7|White|
|8|Not used|
|9|Reset to default color|

### 清屏
|Capname|Description|
|:--|:--|
|smcup|Save screen contents|
|rmcup|Restore screen contents|
|el|Clear from the cursor to the end of the line|
|el1|Clear from the cursor to the beginning of the line|
|ed|Clear from the cursor to the end of the screen
|clear|Clear the entire screen and home the cursor|


## 参考链接
man 1 tput  
man 5 terminfo  
tput(http://linuxcommand.org/lc3_adv_tput.php)