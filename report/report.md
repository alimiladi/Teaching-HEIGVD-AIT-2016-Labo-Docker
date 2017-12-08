# Lab4 : Docker
#### Authors : Ali Miladi & Dany Tchente

## Table of contents
|*Section #*|*Chapter*				  		|
|-----------|-------------------------------|
|1			|[*Introduction*](#Intro)		|
|2			|[*Task 0*](#Task0)      		|
|3			|[*Task 1*](#Task1)      		|
|4			|[*Task 2*](#Task2)      		|
|5			|[*Task 3*](#Task3)      		|
|6			|[*Task 4*](#Task4)      		|
|7			|[*Task 5*](#Task5)      		|
|8			|[*Task 6*](#Task6)      		|
|9			|[*Difficulties*](#Difficulties)|
|10			|[*Conclusion*](#Conclusion)    |

## <a name="Intro"></a>1.	Introduction
In this lab we will deploy a web application in a two-tier fashion similarily to what we have done in the [*previous lab*](https://github.com/alimiladi/Teaching-HEIGVD-AIT-2015-Labo-Load-Balancing). 

We will practice docker manipulations in an infrastructure having a load balander and several `nodejs` servers behind it.

We will use an HAProxy load balancer based on the 1.5 version.
For this lab, we use this [*github repo*](https://github.com/alimiladi/Teaching-HEIGVD-AIT-2016-Labo-Docker).

The goal of this lab is to actually add and remove nodes without having to rebuild the HAProxy image.

Through the different steps of the lab, we will comment the realised manipulations, provide explanations for them and probably sceenshots in order to be the clearest possible.

## <a name="Task0"></a>2.	Task 0 : Identify issues and install the tools
1. <a name="M1"></a>**[M1]** 
	No, we can't use the current solution for a production environment. Actually, even if this infrastructure is somehow scalable, it is not yet ready to be deployed in a prod environment. 
	The reason behind this is the fact that we don't have yet an automated handling of the new arrived/removed nodes and instead we have to do this manually by modifying the config file of HAProry and rebuilding the image.
	This isn't nice at all for the reason that we interrupt the load balancer service for a while when we restart it so we loose disponibility.

2. <a name="M2"></a>**[M1]**
	a)With the actual configuration, in order to add a new webapp container:
	we need to add it manually in the haproxy.cfg file `server s3 <s3>:3000 check cookie s3`.
	b) We have to add the container to the `/vagrant/ha/scripts/run.sh` script, in order for the `haproxy` container to know about this new node.
	```
	sed -i 's/<s3>/$S3_PORT_3000_TCP_ADDR/g' /usr/local/etc/haproxy/haproxy.cfg
	```
	c) Next we need to modify the script `provision.sh` in order to automatically start the new container in the `vagrant` VM when typing `vagrant provision`.
	```
	docker rm -f s3 2>/dev/null || true
	docker run -d --name s3 softengheigvd/webapp
	```
	d) We need then to inform the `HAProxy` container that there is this new image. We do this by rebuilding the latter's image and re-running it by specifying a link to the fresh webapp image. This is done automatically when we run the `provision.sh` or typing `vagrant provision` in our environment's command line.
	This is not yet the end, we need also to modify the last line of this provision script. This line is responsible for running the `HAProxy`  container and linking it with the `webapp` containers. So we nee to add a new link to the fresh webapp container.
	```
	docker run -d -p 80:80 -p 1936:1936 -p 9999:9999 --link s1 --link s2 --link s3 --name ha softengheigvd/ha
	```
	e) Finally we need to reprovision the VM. We can do it by running the `reprovision.sh` script.
	```./reprovision.sh```or typing `vagrant provision` in our personal environment CLI. 
This is actually tedious and error prone.

## <a name="Task1"></a>3.	Task 1 : Add a process supervisor to run several processes
## <a name="Task2"></a>4.	Task 2 : Add a tool to manage membership in the web server cluster
## <a name="Task3"></a>5.	Task 3 : React to membership changes
## <a name="Task4"></a>6.	Task 4 : Use a template engine to easily generate configuration files
## <a name="Task5"></a>7.	Task 5 : Generate a new load balancer configuration when membership changes
## <a name="Task6"></a>8.	Task 6 : Make the load balancer automatically reload the new configuration
## <a name="Difficulties"></a>9.	Encountered difficulties
## <a name="Conclusion"></a>10.	Conclusion