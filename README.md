# 개요
ECS 와 Fargate 를 활용한 CRUD 백엔드 인프라 구성입니다.

요구사항
- AWS 사용
- CI / CD 구성
- CRUD 생성
- IaC 구성 (Terraform 을 사용하여 구현함)
- ELB 사용
- Route53 적용

## 아키텍쳐
### 인프라 아키텍쳐
ECS 와 Fargate 를 활용한 아키텍쳐입니다. ALB 를 통해 백엔드 서버에 접근이 가능하도록 하였으며 ACCESS_KEY 를 통한 자격증명 대신 IAM 임시자격증명을 통해 Fargate 에 역할을 부여하여 제한적인 권한을 사용하도록 하였습니다.
![image](https://github.com/SangYunLeee/markectboro-ecs-project/assets/35091494/a5c6cff1-96f7-4671-a01c-c14b19e55038)

### CI / CD 아키텍쳐
백앤드 소스가 변경되면 도커 이미지 생성 후 ECR 에 태그와 함께 저장한 뒤, Task-Definition 을 변경함을 통해 CI / CD 가 이루어집니다.

![image](https://github.com/SangYunLeee/markectboro-ecs-project/assets/35091494/54535e93-68e2-4ec2-aac4-a9757a9f6bdc)




## API 명세서
[POSTMAN 명세서 링크](https://www.postman.com/interstellar-meteor-533643/workspace/markectboro-product/request/4514456-19475b72-1888-488f-887e-d03de5deb4d0)
## 동작 방법
---
### STEP 1: 테라폼을 통한 리소스 프로비져닝

```bash
# 소스 다운로드
$ git clone https://github.com/SangYunLeee/markectboro-ecs-project.git

# 테라폼 폴더로 이동
$ cd terraform

# 테라폼 초기화
$ terraform init

# 테라폼 리소스 프로비져닝
$ terraform apply
```
이 때에 아래와 같이 `로드밸런서 주소` 와 `ECR 레포지토리 주소` 를 획득합니다.
```
Outputs:

loadbalancer_dns = "tf-marketboro-alb-1730107725.ap-northeast-2.elb.amazonaws.com"
repository_url = "587649217574.dkr.ecr.ap-northeast-2.amazonaws.com/tf-marketboro-backend"
```
### STEP 2: ECR 에 도커 이미지 업로드
1. `backend` 폴더 안의 `docker-compose.yaml` 파일 수정합니다.
`terraform apply` 시에 얻었던 `output` 의 `repository_url` 을 이용해 `image` 키 값을 변경합니다.
> `image` 의 tag 값은 `0.1` 로 지정하여 진행하겠습니다.
```yaml
# docker-compose.yaml
image: sororiri/marketboro:0.5
=>
# image: {repository_url}:0.1
image: 587649217574.dkr.ecr.ap-northeast-2.amazonaws.com/tf-marketboro-backend:0.1
```
2. 도커 이미지를 생성합니다.
`docker-compose build backend`
3. 도커 이미지를 업로드(PUSH)합니다.
`docker-compose push backend`

### STEP 3: 테라폼에 도커 이미지 반영
1. 테라폼 내 `variables.tf` 의 `API_VERSION` 의 값을 `NONE` 에서 `0.1` 로 변경합니다.
2. `terraform apply` 로 적용합니다.
### STEP 2: CRUD 동작 확인
>  [POSTMAN API 명세서 링크](https://www.postman.com/interstellar-meteor-533643/workspace/markectboro-product/request/4514456-19475b72-1888-488f-887e-d03de5deb4d0) 

#### 아이템 생성
```bash
# curl -X POST {로드밸런서 URL}/items \
   -H "Content-Type: application/json" \
   -d '{"title": "한우", "description": "돼지고기는 맛있다"}'
   
$ curl -X POST http://tf-record-alb-1975603344.ap-northeast-2.elb.amazonaws.com/items \
   -H "Content-Type: application/json" \
   -d '{"title": "한우", "description": "돼지고기는 맛있다"}'

response:
{"id":"d52203c6-e470-45f1-93f8-ca9f52083fc9","title":"한우","description":"돼지고기는 맛있다"}
```

#### 전체 아이템 획득
```bash
# curl {로드밸런서 URL}/items
   
$ curl http://tf-record-alb-1975603344.ap-northeast-2.elb.amazonaws.com/items

response:
[{"id":{"S":"d52203c6-e470-45f1-93f8-ca9f52083fc9"},"title":{"S":"한우"},"author":{"S":"돼지고기는 맛있다"}}]
```


### STEP 4: 도메인을 통한 접근
1. `AWS` 에서 원하는 도메인을 구매합니다. `example.click` 이라고 가정하겠습니다.
2. 테라폼 소스에서 `variables.tf` 내 `DOMAIN_NAME` 값을 `example.click` 로 변경합니다.
2. 도메인을 구매할 때에 생성된 `Route53` 내의 `호스트영역` 을 제거합니다.
3. 테라폼을 통해 생성되었던 `호스트 영역` 내 `DNS 서버 정보` 를 복사하여 아래의 그림과 같이 `등록된 도메인` 의 `이름 서버 편집` 에 붙여 넣습니다.
![](https://velog.velcdn.com/images/sororiri/post/cb6b7687-4cd1-41d7-8626-b8320894f8b4/image.png)
> 본인의 경우 네임서버가 반영되는데에 약 40분 미만의 시간이 걸렸습니다.
4. 아래와 같이 `로드밸런서의 도메인` 대신 `구매한 도메인` 으로 접근이 가능합니다.
```bash
# curl api.{로드밸런서 dns}/items
$ curl http://api.example.click/items

response:
[{"id":{"S":"d52203c6-e470-45f1-93f8-ca9f52083fc9"},"title":{"S":"한우"},"author":{"S":"돼지고기는 맛있다"}}]
```

