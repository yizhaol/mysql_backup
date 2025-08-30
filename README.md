# mysql数据库备份
## 功能：
1. 备份mysql数据库
2. 将信息通过钉钉机器人进行推送
## 配置文件
 修改.env文件
## 使用方法
1. 拉取github项目
2. 修改配置文件.env文件改为自己的数据库及钉钉配置
   3. 运行docker-compose.yml文件 
   >最基本的前台启动（用于调试，Ctrl+C 可停止）
   > 
   > docker-compose up

   >更常用的方式：后台启动（守护进程模式
   > 
   > docker-compose up -d

   > 停止所有正在运行的服务，但保留容器
   > 
   > docker-compose stop

    
    