library bwu_docker.src.remote_api.dart;

import 'dart:convert' show JSON;
import 'dart:async' show Future, Stream;
import 'package:http/http.dart' as http;
import 'data_structures.dart';

class DockerConnection {
  static const headers = const {'Content-Type': 'application/json'};
  final String host;
  final int port;
  http.Client client;
  DockerConnection(this.host, this.port) {
    client = new http.Client();
  }

  /// Send a POST request to the Docker service.
  Future<Map> _post(String path, {Map json, Map query}) async {
    String data;
    if (json != null) {
      data = JSON.encode(json);
    }
    final url = new Uri(
        scheme: 'http',
        host: host,
        port: port,
        path: path,
        queryParameters: query);

    final http.Response response = await client.post(url,
        headers: headers, body: data);
    if(response.statusCode < 200 && response.statusCode >= 300) {
      throw 'ERROR: ${response.statusCode} - ${response.reasonPhrase}';
    }
    if (response.body != null && response.body.isNotEmpty) {
      return JSON.decode(response.body);
    }
    return null;
  }

  Future<dynamic> _get(String path, {Map<String,String> query}) async {
    final url = new Uri(
        scheme: 'http',
        host: host,
        port: port,
        path: path,
        queryParameters: query);
    final http.Response response = await client.get(url, headers: headers);
    if(response.statusCode < 200 || response.statusCode >= 300) {
      throw 'ERROR: ${response.statusCode} - ${response.reasonPhrase}';
    }

    if (response.body != null && response.body.isNotEmpty) {
      return JSON.decode(response.body);
    }
    return null;
  }

  /// Request the list of containers from the Docker service.
  /// [all] - Show all containers. Only running containers are shown by default (i.e., this defaults to false)
  /// [limit] - Show limit last created containers, include non-running ones.
  /// [since] - Show only containers created since Id, include non-running ones.
  /// [before] - Show only containers created before Id, include non-running ones.
  /// [size] - Show the containers sizes
  /// [filters] - filters to process on the containers list. Available filters:
  ///  `exited`=<[int]> - containers with exit code of <int>
  ///  `status`=[ContainerStatus]
  Future<Iterable<Container>> containers({bool all, int limit, String since,
      String before, bool size, Map<String, List> filters}) async {
    Map<String,String> query = {};
    if (all != null) query['all'] = all.toString();
    if (limit != null) query['limit'] = limit.toString();
    if (since != null) query['since'] = since;
    if (before != null) query['before'] = before;
    if (size != null) query['size'] = size.toString();
    if (filters != null) query['filters'] = JSON.encode(filters);

    final List response = await _get('/containers/json', query: query);
    return response.map((e) => new Container.fromJson(e));
  }

  /// Create a container from a container configuration.
  Future<CreateResponse> create(CreateContainerRequest request, {String name}) async {
    Map query;
    if(name != null) {
      assert(containerNameRegex.hasMatch(name));
      query = {'name': name};
    }
    final Map response =
        await _post('/containers/create', json: request.toJson(), query: query);
    return new CreateResponse.fromJson(response);
  }

  Future<SimpleResponse> start(Container container) async {
    final Map response = await _post('/containers/${container.id}/start');
    return new SimpleResponse.fromJson(response);
  }

  Future<TopResponse> top(Container container, {String psArgs}) async {
    Map query;
    if(psArgs != null) {
      query = {'ps_args': psArgs};
    }

    final Map response = await _get('/containers/${container.id}/top', query: query);
    return new TopResponse.fromJson(response);

  }
}

