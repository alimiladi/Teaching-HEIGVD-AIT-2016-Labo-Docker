# Lab4 : Docker


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

2. <a name="M2"></a>**[M2]**

	a)	With the actual configuration, in order to add a new webapp container:
	we need to add it manually in the haproxy.cfg file `server s3 <s3>:3000 check cookie s3`.

	b) 	We have to add the container to the `/vagrant/ha/scripts/run.sh` script, in order for the `haproxy` container to know about this new node.
	```bash
	sed -i 's/<s3>/$S3_PORT_3000_TCP_ADDR/g' /usr/local/etc/haproxy/haproxy.cfg
	```

	c) 	Next we need to modify the script `provision.sh` in order to automatically start the new container in the `vagrant` VM when typing `vagrant provision`.
	```bash
	docker rm -f s3 2>/dev/null || true
	docker run -d --name s3 softengheigvd/webapp
	```

	d) 	We need then to inform the `HAProxy` container that there is this new image. We do this by rebuilding the latter's image and re-running it by specifying a link to the fresh webapp image. This is done automatically when we run the `provision.sh` or typing `vagrant provision` in our environment's command line.
	This is not yet the end, we need also to modify the last line of this provision script. This line is responsible for running the `HAProxy`  container and linking it with the `webapp` containers. So we nee to add a new link to the fresh webapp container.
	```bash
	docker run -d -p 80:80 -p 1936:1936 -p 9999:9999 --link s1 --link s2 --link s3 --name ha softengheigvd/ha
	```

	e) 	Finally we need to reprovision the VM. We can do it by running the `reprovision.sh` script.
	`./reprovision.sh`or typing `vagrant provision` in our personal environment CLI. 
	
	This is actually tedious and error prone.

3. <a name="M3"></a>**[M3]**

	At a high level, we would use two different approaches. 

	First, we would implement a sort of registry which is close to the HAProxy and the nodes. Then every node would write in this registry to announce its arrival or departure and the proxy would need to be notified when such a modification is done. This latter would then update it's `haproxy.cfg` file.

	The second way to do this is to have a kind of a distributed deamon application which would run on all the infrastructure components (nodes and load balancer). This application would be responsible for having all the informations up to date in at all the components. Then every node would install an instance of the application and it would then be aware of it. Moreover, when it happens that a node goes down, its instance of the application would stop running and the all the other compnents would be informed instantaneously.

4. <a name="M4"></a>**[M4]**

	The fact that the backend-nodes' names are hard coded in the `haproxy.cfg` file makes it static and its configuration really tedious. The solution to overcome this problem is the second alternative exposed in the question [**M3**](#M3).

	We actually would need a decentralized cluster membership, failure detection, and orchestration tool like `SERF`. 

	This tool seems to be really powerful. It relies on an efficient and lightweight gossip protocol to communicate between the nodes. Its principle is to run agents on each component of the infrastructure. These agents are going to exchange messages periodically with each other using the gossip protocol. Therefore, each node will be aware of all the other members running `serf` agents including the load balancer. Thus, this latter can update it's configuration file on the fly.

5. <a name="M5"></a>**[M5]**

	Although `Docker` recommands to use only one service per container, it is absolutely possible to [run multiple services](https://docs.docker.com/engine/admin/multi-service_container/) on a single container. 

	According to `Docker`'s documentation, we can do this in two dfferent fashions. This only depends on whether we want to manage the services, kill them and start them easily or not.

	The first approach is to write a script that run srvices in background and invoke it in the `CMD`  command at the end of the `Dockerfile`.

	The second approach is to use a sort of a client/server system that allows managing a lot of processes, run it on a container and let it control all the desired services (start and stop them). Such systems exist and are even well-known indeed when surching a little bit on the web, we found systems like [supervisord](https://hub.docker.com/r/baffledbear/supervisord/), [systemd](https://hub.docker.com/r/centos/systemd/) or [CRM](https://hub.docker.com/r/crmcore/crm-linux/).

	Therefore, such a solution is not possible for our actual inffrastructure due to the fact that the containers only run one service at a time.

6. <a name="M6"></a>**[M6]**

	As the script `run.sh` hardcodes the IP adresses in the configuration file of `HAProxy`, this is not dynamic at all and the introduction of new nodes won't impact the load balancer. So we need to introduce a tool to do this cleanly.

	The usage of a [templating engine](https://www.haproxy.com/blog/dynamic-scaling-for-microservices-with-runtime-api/) would substantially facilitate this approach.
	There are a lot of web templatong engines, we are going to mention some of them :

	* [Jinja2](http://jinja.pocoo.org/docs/2.10/)
	* [Facelets](https://docs.oracle.com/javaee/6/tutorial/doc/giepx.html)
	* [Haml](http://haml.info/)
	* [Template-toolkit](http://www.template-toolkit.org/)


#### Delivrables

1. Stats page

![Task0Stats](https://github.com/alimiladi/Teaching-HEIGVD-AIT-2016-Labo-Docker/blob/master/assets/img/Task-0--Stats-page.PNG)

2. Github repo

The click [here](https://github.com/alimiladi/Teaching-HEIGVD-AIT-2016-Labo-Docker) for the lab repo.


## <a name="Task1"></a>3.	Task 1 : Add a process supervisor to run several processes
1.	**Stats page**

![Task1Stats](https://github.com/alimiladi/Teaching-HEIGVD-AIT-2016-Labo-Docker/blob/master/assets/img/Task-1--Stats-page.PNG)

2.	
	i)	**Difficulties for this task**
	The biggest difficulty we had encountered in this task is to understand what's going on under the hood with an init system.
	It was pretty much straightforward to understand what an init system is but understanding how it does work was the hardest part.

	ii)	**Why are we installing a process supervisor ?**
	We found the need to install a process supervisor (init system) in order to be able to run more than one service per container. We needed to do this because we have discovered that we can install a `serf` agent as a service in each container next to it's main service (webapp or load balancer) in order to modify the load balancer's configuration on the fly when we add/remove backend nodes.
	When searching a liitle bit, we found that an init system is the first process started at the boot of `UNIX-like` system which runs as a deamon. This process is then responsible for starting and stopping the other applications/services of the host machine (in our case host container).
	After having a look at their [Github repo](https://github.com/just-containers/s6-overlay), we found out that `S6-overlay` needs to be started in each container and there is no more need to start a webapp or haproxy application.
	```
	ENTRYPOINT ["/init"]
	``` 
	`S6-overlay` then starts the desired services by executing all the `run` scripts under 
	```bash
	/etc/services.d/
	```
	That's the reason why we have placed our previous running scripts under `/etc/services.d`. We can observe that we have exaclty the same result at the end of the manipulation by taking a look at the `stats page` above.


## <a name="Task2"></a>4.	Task 2 : Add a tool to manage membership in the web server cluster
1.	**Logs**

	The logs of all the infrastructure components are stored under 
	```bash
	/logs/task\ 2/
	logs/
	`-- task 2
	    |-- ha
	    |-- s1
	    `-- s2
	``` 
	* [Before setting up DNS automatic resolution](https://github.com/alimiladi/Teaching-HEIGVD-AIT-2016-Labo-Docker/blob/master/logs/task%202/Default-DNS-Bridged-order-ha-s1-s2)
	* [After setting up the custom network and activating embedded DNS](https://github.com/alimiladi/Teaching-HEIGVD-AIT-2016-Labo-Docker/blob/master/logs/task%202/HEIG-DNS-Bridged-order-ha-s1-s2)
	* Result of the network `heig` inspection 
	```bash
	vagrant@ubuntu-14:/vagrant$ docker network inspect heig
	[
	    {
	        "Name": "heig",
	        "Id": "584686f157ff957ea225642b82c86dc49306e35ff1427e7004f240d4b5fb779a",
	        "Created": "2017-12-13T09:43:44.98084299Z",
	        "Scope": "local",
	        "Driver": "bridge",
	        "EnableIPv6": false,
	        "IPAM": {
	            "Driver": "default",
	            "Options": {},
	            "Config": [
	                {
	                    "Subnet": "172.18.0.0/16",
	                    "Gateway": "172.18.0.1"
	                }
	            ]
	        },
	        "Internal": false,
	        "Attachable": false,
	        "Ingress": false,
	        "ConfigFrom": {
	            "Network": ""
	        },
	        "ConfigOnly": false,
	        "Containers": {
	            "0553e90b363ab723ce060e05e70c8700c17b525aa2696fc46afbaa576d8a5062": {
	                "Name": "s1",
	                "EndpointID": "3859869f0fa7afaa9c890d7514daf2eecbf982d8fd5390edf4906ee358a8db7e",
	                "MacAddress": "02:42:ac:12:00:02",
	                "IPv4Address": "172.18.0.2/16",
	                "IPv6Address": ""
	            },
	            "64bc281ba970cedf7aab6a4415bd6332a6c27b3b6d4ecf94759ed724ded5dbaf": {
	                "Name": "s2",
	                "EndpointID": "91d3b299eec81332dfd5d0e7a1735ec2792b869dd40b2a800406fd87819110e0",
	                "MacAddress": "02:42:ac:12:00:03",
	                "IPv4Address": "172.18.0.3/16",
	                "IPv6Address": ""
	            },
	            "a77f397c9d32d344109264884c6f5735c8ac04245255a0f0e067a16bf0343c65": {
	                "Name": "ha",
	                "EndpointID": "a80cf3148b44ddd32d8dc9f91ab92e9349932b2d5b0da9ca5055d6eca9b0bb53",
	                "MacAddress": "02:42:ac:12:00:04",
	                "IPv4Address": "172.18.0.4/16",
	                "IPv6Address": ""
	            }
	        },
	        "Options": {},
	        "Labels": {}
	    }
	]
	``` 
	We can see in the inspection above that the three containers had actually joined the network.

2.	**What's the problem with the current solution ?**
	
	The problem with the current solution is that we attach the `serf` cluster to the `ha` container. This is actually an issue because it imposes a precise order when starting the containers. Indeed, we need to start the `ha` container first and then start the backend nodes afterwards.

	In the case that we start the webapps first, they are not going to be able to join the cluster as this one is going to be started by the `ha` container which doesn't exist yet.

3.	**How does Serf works ?**

	`Serf` relies on a `GOSSIP` protocol to establish a communication between nodes. Each node runs a `Serf agent` which exchange messages with other agents. 
	A membership cluster is aware of all its members, their departures and the arrival of new ones. 

	**Gossip protocol**

	The underlying `GOSSIP` protocol relies on  `SWIM: Scalable Weakly-consistent Infection-style Process Group Membership Protocol` which is built on top of `UDP`. Complete state exchanges are done periodically using `TCP`. Failure detection is acheived by random probing of the running agents of the cluster. If it doesn't ack within a fixed threshold, it is considered as failed.

	**Solutions to solve similar situations ?**

	Another solution to this problem would be to have a centrelized registry which is aware of all the nodes in the cluster and can do updates on the load balancers' container. This method seems to be good but the problem is that we have implemented a single point of failure which is not good.


## <a name="Task3"></a>5.	Task 3 : React to membership changes

1. **Docker logs**
	
	All the logs requested for this task are stored under [task 3](https://github.com/alimiladi/Teaching-HEIGVD-AIT-2016-Labo-Docker/blob/master/logs/task%203) and are divided in sections as described below

	* Only [ha](https://github.com/alimiladi/Teaching-HEIGVD-AIT-2016-Labo-Docker/blob/master/logs/task%203/Only-ha-join) is running
	* When we started s1
		* [ha](https://github.com/alimiladi/Teaching-HEIGVD-AIT-2016-Labo-Docker/blob/master/logs/task%203/s1-started-ha-logs)
		* [s1](https://github.com/alimiladi/Teaching-HEIGVD-AIT-2016-Labo-Docker/blob/master/logs/task%203/s1-started-s1-logs)
	* When we started s2
		* [ha](https://github.com/alimiladi/Teaching-HEIGVD-AIT-2016-Labo-Docker/blob/master/logs/task%203/s2-started-ha-logs)
		* [s1](https://github.com/alimiladi/Teaching-HEIGVD-AIT-2016-Labo-Docker/blob/master/logs/task%203/s2-started-s1-logs)
		* [s2](https://github.com/alimiladi/Teaching-HEIGVD-AIT-2016-Labo-Docker/blob/master/logs/task%203/s2-started-s2-logs)
	* Logs directly from the `ha` container in the file ```bash /var/logs/serf.log```
		* [ha](https://github.com/alimiladi/Teaching-HEIGVD-AIT-2016-Labo-Docker/blob/master/logs/task%203/logs-from-ha-container)

## <a name="Task4"></a>6.	Task 4 : Use a template engine to easily generate configuration files
## <a name="Task5"></a>7.	Task 5 : Generate a new load balancer configuration when membership changes
## <a name="Task6"></a>8.	Task 6 : Make the load balancer automatically reload the new configuration
## <a name="Difficulties"></a>9.	Encountered difficulties
## <a name="Conclusion"></a>10.	Conclusion