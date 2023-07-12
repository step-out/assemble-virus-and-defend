# assemble-virus-and-defend
厦门大学2021级人工智能系汇编语言大作业

Virus, kill and defend virus file in assemble language.用汇编语言写成的病毒，杀毒和防护文件

由厦门大学2021级本科生马承乾，连国鑫，金为轩，李葳骏，李聪，李亚轩合作完成，具体分工可见code_and_doc文件夹下分工文件。

病毒文件：可以感染同一文件夹下的所有exe文件，是所有exe文件都在正常运行功能之前输出一段病毒信息，具有传染性。

杀毒文件：运行以后可以杀死同一文件夹下所有带病毒的exe文件，使其恢复正常功能。

防护文件：一颗防护的种子，运行该文件以后，再运行病毒文件时会立刻输出病毒提示信息，随后将病毒杀死。使用内存驻留技术实现。

本项目中包括对virus, kill, defend文件的源代码和对代码的详细解释。

效果如下：

# virus文件（myinfect.exe文件）：
![image](https://github.com/malaozei/assemble-virus-and-defend/assets/94264539/4d9c4f38-fcc1-4971-b61f-e0b913d62f60)
![image](https://github.com/malaozei/assemble-virus-and-defend/assets/94264539/965263ca-bc6d-4fcd-b2d9-4dc1a0ae94e9)

感染成功，且不影响原程序的功能，也不会重复感染。
# kill文件：
![image](https://github.com/malaozei/assemble-virus-and-defend/assets/94264539/f150c3d0-a4b3-4e05-a31d-3cfc7f7940e1)

# defend文件：
![image](https://github.com/malaozei/assemble-virus-and-defend/assets/94264539/9f0f8042-154b-4252-90d0-72d71ceb2458)
# 使用方法：
使用dosbox软件，用debug.exe将asm文件编译为obj文件，再用link.exe链接为exe文件，或者vscode中的masm插件。

更多说明见实验报告，其中有包含流程图，程序思路，结果示范在内的极其详细的说明。
