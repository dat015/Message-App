import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:first_app/data/api/api_client.dart';
import 'package:first_app/data/repositories/Chat/websocket_service.dart';
import 'search_event.dart';
import 'search_state.dart';

class SearchUsersBloc extends Bloc<SearchUsersEvent, SearchUsersState> {
  final ApiClient apiClient;
  final WebSocketService webSocketService;
  final int currentUserId;
  late StreamSubscription _messageSubscription;
  late StreamSubscription _connectionSubscription;

  SearchUsersBloc({
    required this.apiClient,
    required this.webSocketService,
    required this.currentUserId,
    required List<dynamic> initialSearchResults,
  }) : super(SearchUsersState(searchResults: initialSearchResults)) {
    _setupWebSocketListeners();
    on<SendFriendRequestEvent>(_onSendFriendRequest);
    on<CancelFriendRequestEvent>(_onCancelFriendRequest);
    on<UpdateWebSocketMessageEvent>(_onUpdateWebSocketMessage);
    on<UpdateConnectionStateEvent>(_onUpdateConnectionState);
  }

  void _setupWebSocketListeners() {
    if (!webSocketService.isConnected) {
      webSocketService.connect();
    }

    _messageSubscription = webSocketService.onMessage.listen((message) {
      add(UpdateWebSocketMessageEvent(message));
    });

    _connectionSubscription = webSocketService.onConnectionState.listen((isConnected) {
      add(UpdateConnectionStateEvent(isConnected));
    });
  }

  Future<void> _onSendFriendRequest(SendFriendRequestEvent event, Emitter<SearchUsersState> emit) async {
    try {
      final response = await apiClient.post(
        'api/friends/send-request',
        data: {
          'senderId': currentUserId,
          'receiverId': event.receiverId,
        },
      );
      final updatedResults = List<dynamic>.from(state.searchResults);
      updatedResults[event.index]['relationshipStatus'] = response['relationshipStatus'] ?? 'PendingSent';
      emit(state.copyWith(searchResults: updatedResults));
    } catch (e) {
      // Lỗi sẽ được xử lý trong UI qua listener
    }
  }

  Future<void> _onCancelFriendRequest(CancelFriendRequestEvent event, Emitter<SearchUsersState> emit) async {
    try {
      await apiClient.post(
        '/api/Friends/reject-request',
        data: {
          'senderId': currentUserId,
          'receiverId': event.receiverId,
        },
      );
      final updatedResults = List<dynamic>.from(state.searchResults);
      updatedResults[event.index]['relationshipStatus'] = 'NotSent';
      emit(state.copyWith(searchResults: updatedResults));
    } catch (e) {
      // Lỗi sẽ được xử lý trong UI qua listener
    }
  }

  void _onUpdateWebSocketMessage(UpdateWebSocketMessageEvent event, Emitter<SearchUsersState> emit) {
    if (event.message['Type'] == 'RequestAccepted' ||
        event.message['Type'] == 'RequestRejected' ||
        event.message['Type'] == 'RequestCancelled') {
      final receiverId = event.message['ReceiverId'];
      final senderId = event.message['SenderId'];
      final updatedResults = List<dynamic>.from(state.searchResults);

      for (var user in updatedResults) {
        if (user['id'] == receiverId || user['id'] == senderId) {
          user['relationshipStatus'] = event.message['Type'] == 'RequestAccepted'
              ? 'Accepted'
              : event.message['Type'] == 'RequestRejected'
                  ? 'Rejected'
                  : 'NotSent';
          break;
        }
      }
      emit(state.copyWith(searchResults: updatedResults));
    }
  }

  void _onUpdateConnectionState(UpdateConnectionStateEvent event, Emitter<SearchUsersState> emit) {
    emit(state.copyWith(isWebSocketConnected: event.isConnected));
  }

  @override
  Future<void> close() {
    _messageSubscription.cancel();
    _connectionSubscription.cancel();
    return super.close();
  }
}