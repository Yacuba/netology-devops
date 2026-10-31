from os import getenv
from flask import Flask, request, make_response, jsonify
from prometheus_flask_exporter import PrometheusMetrics, NO_PREFIX
from passlib.hash import pbkdf2_sha256
import jwt

server = Flask(__name__)
metrics = PrometheusMetrics(server, defaults_prefix=NO_PREFIX, buckets=[0.1, 0.5, 1, 1.5, 2], default_labels={"app_name": "security"})
metrics.info('app_info', 'Application info', version='1.0')

jwt_key = 'secret'
data = {
    'bob': pbkdf2_sha256.hash('qwe123')
}

@server.route('/status', methods=['GET'])
def status():
    return {'status': 'OK'}

@server.route('/v1/user', methods=['GET'])
def get_user():
    return jsonify({'users': list(data.keys())})

@server.route('/v1/user', methods=['POST'])
def register_user():
    if not request.json or 'login' not in request.json or 'password' not in request.json:
        return make_response(jsonify({'error': 'Bad request'})), 400
    login = request.json['login']
    password = request.json['password']
    data[login] = pbkdf2_sha256.hash(password)
    return jsonify({'status': 'user created', 'login': login}), 201

@server.route('/v1/token', methods=['POST'])
def login():
    if not request.json or 'login' not in request.json or 'password' not in request.json:
        return make_response(jsonify({'error': 'Bad request'})), 400

    login = request.json['login']
    password = request.json['password']
    
    if login not in data:
        return make_response(jsonify({'error': 'Unknown login or password'})), 401

    pwd_hash = data[login]
    if not pbkdf2_sha256.verify(password, pwd_hash):
        return make_response(jsonify({'error': 'Unknown login or password'})), 401

    token = jwt.encode({'sub': login}, jwt_key, algorithm="HS256")
    return token

@server.route('/v1/token/validation', methods=['GET'])
def validate():
    auth_header = request.headers.get('Authorization')

    if not auth_header:
        return make_response(jsonify({'error': 'Missing Authorization header'})), 401 
    
    try:
        auth_header_parts = auth_header.split(' ')
        auth_schema = auth_header_parts[0]
        auth_token = auth_header_parts[1]
    except IndexError:
        return make_response(jsonify({'error': 'Invalid Authorization header'})), 401 

    if auth_schema != 'Bearer':
        return make_response(jsonify({'error': 'Invalid Authorization schema'})), 401 

    if not auth_token:
        return make_response(jsonify({'error': 'Invalid Authorization value'})), 401 

    try:
        decoded = jwt.decode(auth_token, jwt_key, algorithms=["HS256"])
        return jsonify(decoded), 200
    except jwt.ExpiredSignatureError:
        return make_response(jsonify({'error': 'Signature expired'}), 401)
    except jwt.InvalidTokenError:
        return make_response(jsonify({'error': 'Invalid token'}), 401)

if __name__ == '__main__':
    port = int(getenv('PORT') or '3000')
    server.run(host='0.0.0.0', port=port)