# Documentation

In dit document wordt ingegaan op de code die gebruikt is om deze requirements uit te voeren. En wat de keuzes waren om tot deze oplossing te komen.

## Requirement 1

```bash {data-filename="add_games.sh"}
init_data() {
    data="{"'"type"'": "'"Game"'", "'"fields"'": {";
}

FILE='chess.pgn';

keywords=("Event" "Site" "Date" "Round" "WhiteElo" "BlackElo" "White" "Black" "Result" "ECO");

init_data;
while read value; do
    if [[ ! $value =~ ^1\. ]]; then
        for keyword in "${keywords[@]}"; do
            if [[ "$value" == "[$keyword"* ]]; then
                content=$(grep -o '".*"' <<< "$value");
                data="$data \"$keyword\": $content,";

                break;
            fi
        done

    else
        data=${data%?}; # Remove last comma for proper JSON syntax
        data="$data}, \"moves\": \"$value\"}";

        curl -d "$data" -H "Content-Type: application/json" -X POST $1;

        init_data;
    fi
done <"$FILE"
```

Om in bash door de data heen te gaan en deze in JSON formaat op te stellen, werd er gekozen om de verschillende velden van een game op te slaan in een array en deze te matchen met elke regel die af gegaan werd in de while loop. Dit ging bij een eerste test goed, maar werd White en Black dubbel afgedrukt, omdat deze ook voorkomen in het woord "WhiteElo" en "Blackelo". 
Dit werd opgelost door met de grep command te zoeken naar de langst mogelijke match, zodat white and black niet dubbel werd meegenomen.
Daarna werden de moves geprint en als laatste met curl een post request gedaan naar de backend, waar deze het opslaat in de sqLite database in de backend zelf of mysql db, aan de hand van de FLASK_ENV variabele.

## Requirement 2

### Dockerfile backend

```Dockerfile {data-filename="Dockerfile"}
FROM python:3.8-slim

# Install poetry
RUN pip install poetry

# Set WORKDIR
WORKDIR /app

# Copy current directory to /app
COPY . /app

# Install dependencies
RUN poetry install --no-dev

# Expose port 5001
EXPOSE 5001

CMD ["poetry", "run", "python3", "app.py"]
```

Voor backend werd de Dockerfile ingevuld met de commands die nodig zijn.
De workdir wordt gezet, waarna de contents hier naartoe worden gekopieerd. Daarna, wordt met Poetry alle dependencies geinstalleerd, als eennalaatste wordt poort 5001 exposed. Deze poort is gekozen, omdat de eerder gekozen poort 5000 op MacOS bezet is door andere processen.
Als laatste wordt de backend applicatie gestart.

### Docker-compose

```yaml {data-filename="docker-compose.yml"}
version: "3.9"
services:
    chess_backend:
      container_name: chess_backend_c
      build: ./backend
      ports:
        - "5001:5001"
    chess_frontend:
      container_name: chess_frontend_c
      image: nginx:latest
      ports:
        - "80:80"
      volumes:
        - ./frontend/dist:/usr/share/nginx/html
        - ./frontend/lib:/usr/share/nginx/html/lib
```

In de docker-compose zijn twee services gedefinieerd voor de database, backend en frontend.
De database krijgt een nieuwe lege volume toegewezen om de database in op te slaan en worden de environment variables gezet, zodat de backend connectie kan maken met deze container.

Bij de backend wordt de backend directory gebuild en klaargezet, waarbij naast de database connectie, ook de FLAS_ENV op "production" wordt gezet, zodat er connectie wordt gemaakt met de database service, in plaats van de Sqlite database in de backend zelf.

Als laatste wordt er voor de frontend een frisse installatie van nginx gedaan, waarbij de frontend geserved wordt aan de gebruiker als deze naar http://localhost gaat.
Hiervoor moet de frontend eerst gebouwd worden met de volgende stappen:
1. Installeer de dependencies met npm install.
2. Bouw de applicatie met npm run build. Deze komt in de dist folder.
3. Zet de lib folder in dist voor de dependencies die niet mee gebouwd worden.
Er is een build shell script om dit te automatiseren.

## Requirement 3

```yaml {data-filename="docker-compose.yml"}
chess_db:
  container_name: chess_db_c
  image: mysql:8.0
  restart: always
  environment:
    MYSQL_USER: admin
    MYSQL_PASSWORD: "4oMmmqD6ikDmB"
    MYSQL_DATABASE: chess_db
    MYSQL_ROOT_PASSWORD: "aH7zMVM9XUE5M"
  ports:
    - "3306:3306"
  expose:
    - "3306"
  volumes:
    - chess_db:/var/lib/mysql
  healthcheck:
    test: ["CMD", "mysqladmin" ,"ping", "-h", "localhost"]
    timeout: 20s
    retries: 10
```

Voor de database is een derde container service toegevoegd, waarin de environment variables worden toegevoegd, zodat er een connectie kan worden gemaakt door de backend met deze externe database.

De healthcheck kijkt of MySQL klaar is voor een verbinding.


```yaml {data-filename="docker-compose.yml"}
volumes:
  chess_db:
```

Onderaan wordt een nieuw volume aangemaakt, waar de database data in kan worden opgeslagen.

De backend wordt verder uitgebreid, waarbij er een link met de database container wordt gemaakt en de backend environment variables voor de database connectie krijgt. 
Daarnaast wordt er een FLASK_ENV variabele toegevoegd, zodat de backend connectie maakt met de externe container en niet de lokale SQLite database gebruikt.

De backend word pas opgestart als de database service klaar is (depends_on). "Klaar" is in dit geval als de healthcheck van de database positive is (condition: service_healthy). Dit doen we zodat de backend applicatie bij het opstarten meteen een verbinding met de database kan maken en zo errors voorkomt.

```yaml {data-filename="docker-compose.yml"}
chess_backend:
  container_name: chess_backend_c
  build: ./backend
  depends_on:
    chess_db:
      condition: service_healthy
  environment:
    MYSQL_USER: admin
    MYSQL_PASSWORD: "4oMmmqD6ikDmB"
    MYSQL_DATABASE: chess_db
    FLASK_ENV: production
    MYSQL_HOST: chess_db_c
  ports:
    - "5001:5001"
  links:
    - chess_db
```

## Requirement 4

```yaml {data-filename="gitlab-ci.yml"}
test-backend:
  stage: test
  image: python:3.10
  before_script:
    - cd backend
    - pip install poetry
    - poetry install
  script:
    - poetry run python3 main_tests.py
  artifacts:
    paths:
      - backend/test_results.txt
    expire_in: 1 month
```

Voor het draaien van de tests wordt er een test job toegevoegd aan de gitlab-ci.yml, die bij elke commit die gepushed wordt, gedraaid wordt door Gitlab CI.
Omdat er een run element in het testbestand zit, die een test_result.txt genereert, kan er bij het script niet gebruik gemaakt worden van de 'python unittest' command, maar is hier gekozen om de poetry run python3 main_tests.py command te gebruiken.
Daarna wordt in het artifacts block, de output die de job genereert, dat resultaat bestand opgeslagen in de backend map van de repository. De vervaldatum is ingesteld op 1 maand, zoals gevraagd met expire_in.

## Requirement 5

De infrastructuur is met Terraform opgezet, te vinden in de "infra" directory. Zowel bij backend als database is er gebruik gemaakt van een Docker container.
Dit omdat er dan met de eerder gebruikte Environment variabelen gebruikt kon worden, omdat deze in de Docker image zitten.
Voor alle drie de delen wordt er een bash script gebruikt die alle drie de omgevingen klaar zet. De bash scripts zijn voorzien van echo's om te tonen wat alle regels doen. Alledrie de machines is gekozen om een EC2 met Ubuntu AMI er op te gebruiken.
In het meegekopieerde dockerize.sh script wordt geregeld dat de 'run', 'build' en 'stop' commands kunnen worden uitgevoerd op de containers. Dit is vooral bij de backend handig, nadat er een nieuw image is opgehaald uit de Gitlab registry.

### Backend

```json
resource "aws_network_interface" "ni_f" {
  subnet_id       = aws_subnet.public_subnet_1.id
  security_groups = [aws_security_group.sg_ec2_f.id]

  tags = {
    Name = "ni_f"
  }
}

resource "aws_instance" "ec2_b_1" {
  ami           = data.aws_ami.ami_ubuntu.id
  instance_type = "t2.micro"
  key_name      = aws_key_pair.chess_kp.key_name
  user_data     = file("backend/user_data_b.sh")

  provisioner "file" {
    source      = "backend/docker-compose.yml"
    destination = "/home/ubuntu/docker-compose.yml"

    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = file("id_rsa")
      host        = self.public_ip
    }
  }

  provisioner "file" {
    source      = "../dockerize.sh"
    destination = "/home/ubuntu/dockerize.sh"

    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = file("id_rsa")
      host        = self.public_ip
    }
  }

  network_interface {
    network_interface_id = aws_network_interface.ni_b_1.id
    device_index         = 0
  }

  tags = {
    Name = "ec2_b"
  }
}
```

In de backend Ubuntu EC2 wordt Docker opgezet, zodat de backend image daarop gedraaid kan worden. Daarnaast is voor requirement 6 benodigd dat de image opgehaald kan worden en opnieuw gestart kan worden. Ook daar is deze configuratie voor nodig.

### Database

```json
resource "aws_instance" "ec2_db" {
  ami           = data.aws_ami.ami_ubuntu.id
  instance_type = "t2.micro"
  key_name      = aws_key_pair.chess_kp.key_name
  user_data     = file("database/user_data_db.sh")

  provisioner "file" {
    source      = "database/docker-compose.yml"
    destination = "/home/ubuntu/docker-compose.yml"

    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = file("id_rsa")
      host        = self.public_ip
    }
  }

  network_interface {
    network_interface_id = aws_network_interface.ni_db.id
    device_index         = 0
  }

  tags = {
    Name = "ec2_db"
  }
}
```

Ook de database wordt in een docker image gedraaid, dit zodat de eerder gebruikte Environment Variables hergebruikt kunnen worden, omdat naamgevingen en dergelijke buiten het Docker image andere naamgeving hebben. Op deze manier kan er makkelijker een connectie met de backend opgezet worden.

### Frontend

```json
resource "aws_instance" "ec2_f" {
  ami           = data.aws_ami.ami_ubuntu.id
  instance_type = "t2.micro"
  key_name      = aws_key_pair.chess_kp.key_name
  user_data     = file("frontend/user_data_f.sh")

  provisioner "file" {
    source      = "../frontend/dist/"
    destination = "/home/ubuntu/"

    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = file("id_rsa")
      host        = self.public_ip
    }
  }

  network_interface {
    network_interface_id = aws_network_interface.ni_f.id
    device_index         = 0
  }

  tags = {
    Name = "ec2_f"
  }
}
```

De frontend wordt gerund met nginx, en deze wordt dan ook met het opzetten geinstalleerd, waarna de frontend files daar naartoe worden gekopieerd.

## Requirement 6

Voor deze requirement is de gitlab CI file uitgebreid, met een job voor het bouwen van het image en deze op te slaan in de Gitlab registry van de repository.
Als tweede job wordt de nieuwe image van de backend gedeployed op de EC2 van de Backend in AWS.

### Build job

```yaml
build-backend:
  image: docker:20.10.16
  stage: build
  services:
    - docker:20.10.16-dind
  script:
    - cd backend
    - docker login -u $CI_REGISTRY_USER -p $CI_REGISTRY_PASSWORD $CI_REGISTRY
    - docker build -t registry.gitlab.com/saxion.nl/hbo-ict/2.3-devops/2022-2023/87 .
    - docker push registry.gitlab.com/saxion.nl/hbo-ict/2.3-devops/2022-2023/87
```

Er wordt in deze job een image gebouwd met de 'docker build' command, met '-t' paramter, wordt de naam bepaald van de image.
Als laatste wordt er een docker push gedaan naar de registry, waarna de image beschikbaar is in de Registry van  de Gitlab repository.

### Deploy job

```yaml
deploy-backend:
  image: ubuntu:22.04
  stage: deploy
  script:
    - echo "Installing new image on backend EC2"
    - echo "apt update"
    - apt update
    - echo "apt install openssh-client"
    - apt install --assume-yes openssh-client
    - echo "chmod ssh key"
    - chmod 600 $SSH_PRIVATE_KEY_FILE
    - echo "Stop, build and run backend 1 docker container"
    - ssh -o StrictHostKeyChecking=no -i $SSH_PRIVATE_KEY_FILE ubuntu@54.162.22.104 'sudo bash dockerize.sh stop && sudo bash dockerize.sh build && sudo bash dockerize.sh run'
```

Deze deploy job was iets ingewikkelder. Er wordt eerst een ssh client geinstalleerd, aangezien deze nog niet aanwezig is standaard. Waarna de ssh key wordt toegevoegd aan de lijst met permissions. 
Waarna er een ssh call gedaan wordt naar de Ubuntu EC2 instance van de backend, waarbij de container die draait, gestopt wordt, gebuild en als laatste weer gerund wordt, zodat de backend weer beschikbaar is.
Een probleem wat nu nog blijft, is dat het IP soms wijzigt na het herstarten van de lab service, waardoor deze dan hier aangepast zal moeten worden.

## Requirement 7

Voor deze requirement moet de backend high availability krijgen. Dit betekend dat er meerdere instanties zijn zodat er naar een andere kan worden geschakeld als er iets bij een kapot gaat, of er drukte voor komt.
Dit doen we met een load balancer. Deze kiest welke van de instanties wordt gebruikt. Het heeft ook als voordeel dat de drukte verspreid kan worden.

```json
resource "aws_lb" "lb" {
  name               = "lb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.sg_lb.id]
  subnets            = [aws_subnet.public_subnet_1.id, aws_subnet.public_subnet_2.id]

  tags = {
    Name = "lb"
  }
}

resource "aws_lb_target_group" "lb_tg" {
  name     = "tg"
  port     = 5001
  protocol = "HTTP"
  vpc_id   = aws_vpc.chess_vpc.id

  tags = {
    Name = "lb_tg"
  }
}

resource "aws_lb_listener" "lb_listener" {
  load_balancer_arn = aws_lb.lb.arn
  port              = "5001"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.lb_tg.arn
  }

  tags = {
    Name = "lb_listener"
  }
}
```

Een target group zijn een group van instanties, in dit geval de backends, die door een andere resource gebruikt kunnen worden. De load balancer luistert met de load balancer listener (aws_lb_listener) naar de target group.
Er wordt geluisterd naar poort 5001, en geven ook toegang via de load balancer op poort 5001 zodat de frontend het kan gebruiken.

```json
resource "aws_lb_target_group_attachment" "lb_tg_attachment_ec2_b_1" {
  target_group_arn = aws_lb_target_group.lb_tg.arn
  target_id        = aws_instance.ec2_b_1.id
  port             = 5001
}

resource "aws_lb_target_group_attachment" "lb_tg_attachment_ec2_b_2" {
  target_group_arn = aws_lb_target_group.lb_tg.arn
  target_id        = aws_instance.ec2_b_2.id
  port             = 5001
}
```

Als laatste, worden de twee backend instances toegevoegd aan de load balancer target group. Zodat deze de twee instances kan gebruiken. En bij eventuele drukte kan verspreiden.

### Veiligheid

Nu het verkeer via de load balancer gaat, hoeven de backend instanties niet direct van buiten toegankelijk te zijn. Dit wordt beperkt door bij de security groups van de backends het poort 5001 verkeer alleen toe te staan voor private IP'ss uit hun subnet.

Verkeer naar de database wordt ook beperkt, door alleen inkomend verkeer van de backend instances toe te laten. Dit wordt op een iets andere manier gedaan dan gebruikelijk. Omdat de backends niet perse op het zelfde subnet als de database zijn, kan het niet binnen het netwerk met private IP's opgelost worden. Dus wordt bij het inkomend verkeer van de database, het public IP van de backend gebruikt in de security group.
