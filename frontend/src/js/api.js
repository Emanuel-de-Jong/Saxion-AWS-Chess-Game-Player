const url = 'http://lb-894015992.us-east-1.elb.amazonaws.com:5001/' // backend running here

const headers = {
    'Accept': 'application/json',
    'Content-Type': 'application/json'
}

export default {
    // Get all games in db
    getGames: () => {
        const options = {
            method: 'GET',
            headers: headers
        }
        return fetch(url + 'games', options).then(response => {
            if (response.ok) {
                return response.json();
            }
            throw response; // error
        });
    }
}
