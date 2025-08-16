# Lokaal

## Eisen
- NodeJS 16+
- NPM
- Docker

## Installeren
- Verander indien nodig de `url` in `frontend/src/api.js` naar `http://localhost:5001/`
- Start een terminal in de `frontend` folder
- Voer uit `sudo chmod 770 build.sh`
- Voer uit `bash build.sh`
- Start een terminal in de root folder van de repository
- Voer uit `docker compose up -d`

## Spellen toevoegen
- Start een terminal
- Voer uit `sudo chmod 770 add_games.sh`
- Voer uit `bash add_games.sh http://localhost:5001/games`

## Gebruik
- Ga naar `http://localhost:80/`

---------------------------------------------------------------------------------------------------------

# AWS

## Eisen
- NodeJS 16+
- NPM
- Terraform

## Uploaden
- Indien nodig, maak een `.aws` folder aan in je home folder en voeg er een `credentials` bestand aan toe
- Zet je AWS CLI credentials in het `credentials` bestand
- Start een terminal in de `frontend` folder
- Voer uit `sudo chmod 770 build.sh`
- Voer uit `bash build.sh`
- Start een terminal in de `infra` folder
- Voer uit `terraform init`
- Voer uit `terraform apply`
- Alle resources zijn gestart en aangemaakt, maar er moeten nog wat dingen gewijzigd worden
- Gebruik AWS CLI of AWS Dashboard om URLs en IP's te vinden
- Verander de `MYSQL_HOST` in `infra/backend/docker-compose.yml` naar het IP van `ec2_db`
- Verander de `url` in `frontend/src/api.js` naar `http://[LB URL]:5001/`
- Start een terminal in de `frontend` folder
- Voer opnieuw uit `bash build.sh`
- Terminate `ec2_f`, `ec2_b_1`, `ec2_b_2` en voer opnieuw `terraform apply` uit

## Spellen toevoegen
- Start een terminal
- Voer uit `sudo chmod 770 add_games.sh`
- Voer uit `bash add_games.sh http://[LB URL]:5001/games`

## Gebruik
- Ga naar `http://[EC2_F URL]:80/`
