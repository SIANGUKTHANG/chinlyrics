import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:googleapis_auth/auth_io.dart' as auth;

class NotificationHelper {
  // Na download mi JSON file chung data kha hika ahhin va past te
  static final Map<String, dynamic> _serviceAccountJson = {
    "type": "service_account",
    "project_id": "music-lyrics-ed459", // Na project ID
    "private_key_id": "98aae608404d9f200c0f61e999cf2eef9c2a2a85",
    "private_key":
    "-----BEGIN PRIVATE KEY-----\nMIIEvQIBADANBgkqhkiG9w0BAQEFAASCBKcwggSjAgEAAoIBAQCnwRKVl9C5hJ+2\nzfBIUB3bniiQNFzt1u6+a7OkLUxhzJVE85wkxFUhYygH8WcFVAInYQAGyqYZYV2t\nWBgOs3SUhzvQZwSGKKYdMHJAtBn7NIF/H6T14x2n4bGEdYdbug57jr9Tl1hdkTTS\nrasmdDl7NR2qjIkXZTO5sIR91sEdyaO9tH6vsf+6cJh1mPz9zCL+Hazs/GNQ2qkV\n3RKz+qq81CgnChW8WwLM7ejg2rxHk7odZMHk9jC0KKFlcBMrjFITQyaYZw76aFy7\n+MWChcil/QYtmauvfRAnLzcSkG5HWCnmfmCLOQ9mhfvl2nih5QCcrLSOCKVM9QsV\nOwmXbeMPAgMBAAECggEAUBqnY6x7XGMimvmqz/UF1O2og/elGmNkXKR0QyToUNkO\nvD6xpHLmDcvZ/TT+UzKC1sgAab3R49O1FkW3MynpNNWAr+rJY8C8VbrhC9mUgHpZ\njdkP/eRGMHjauhwfFyN4r/KBlQpzhTaF6UZJsFKWcilycZKrEfNe6EAMfESUscJl\n+JDF19LFm4/BK5Nbg1CIZxjxVSpE28rLvd+ChdSiF5g1gt1G+1xQ+9a6joA8kLM0\nAOZGkNhIz66+7iHNzarxgehNaM5/cc9CzD6EMQcC07wWo3l2qAG26/qFqKTnHN5y\niKlfW8w/hh2pkeYHOGtpyfasNbvafibXeriL5vzTkQKBgQDWgRnMK0f9kF+skwQQ\nkWmE67G5KTmxRGPi5ihdpkqCw3l6q6M2z4LdQc9bS6nBgCTlkBpr8OcGTvpTDVf6\nyqfj9/bcy2kd7e1RJHARe57Bvo9QKLrRhRt41ELwh0OBzkRasEv/bxQzqf9P6JJ3\nXPWfCKgFYtDpr54oAtKVW4YmPwKBgQDINMP418qYLEFmf2cmT2sQ5Pb5SA1l9Wog\nh11OHPz5cDEZpFzSjze/Ysz94XmMBY1k/dVXNUMPe25UIO2R+LFslyRTHgXvkuLf\nnlAcsbb26dvbPCouDiftq4dk9AdnrdksZ8yTH4rDLyjugeVvUemAewDLBxvvJplP\ndPslrYUvMQKBgQCbJDSsXoFq+4i3IH3IHePbpzybVx3LAFPeP+jiEuvBN/AcsRcT\nBXL45Cg9N7RHp48IGfmCKHJvNaAHgZcoZHqZfzak6tnUM8l47om/m1Fvf4vXxh2Y\nfFUqRxtDLBG/SJhXnzrYPFa4JzPpb6S/gBSGOZSMkLPY0JPrDF+SdufHsQKBgCYB\nZkZh6JK0rAGiI9mw79k4Le4qkGiPiwL7z2mZtShA9QEyI3DRQTryrYlweRtsnmfS\ni+JPORjCTLJpwc+ZD01W781bgLL3Blx++CRKVDpRMKxQoo01oLzMeBpg/NrgtL5q\nQfqX3UaqODH2tLBKM3JxZzgjdFkU0bu0sEx5wTOxAoGAXzcL6Po2kVR3RspDT1O7\nV965vIhgXfHd9YF7VjPLbq666ib3b1BmvVXTs7VN0XsG1PCMf86bjfQNfL2inwUt\nfMGPtOX0g7hXR+93Ml25OoFtnYiIxJxYil2k4iHJR2ovtmCX2cXi3aG/QnBwDXhb\nFBCR4yADKokmVD8Ra0J8E0M=\n-----END PRIVATE KEY-----\n",
    "client_email":
    "firebase-adminsdk-6mda5@music-lyrics-ed459.iam.gserviceaccount.com",
    "client_id": "116816243529274947305",
    "auth_uri": "https://accounts.google.com/o/oauth2/auth",
    "token_uri": "https://oauth2.googleapis.com/token",
    "auth_provider_x509_cert_url": "https://www.googleapis.com/oauth2/v1/certs",
    "client_x509_cert_url":
    "https://www.googleapis.com/robot/v1/metadata/x509/firebase-adminsdk-6mda5%40music-lyrics-ed459.iam.gserviceaccount.com"
  };

  static Future<String> _getAccessToken() async {
    List<String> scopes = [
      "https://www.googleapis.com/auth/firebase.messaging"
    ];

    auth.ServiceAccountCredentials credentials =
    auth.ServiceAccountCredentials.fromJson(_serviceAccountJson);
    auth.AutoRefreshingAuthClient client =
    await auth.clientViaServiceAccount(credentials, scopes);
    return client.credentials.accessToken.data;
  }

  static Future<void> sendNotification({
    required String title,
    required String body,
    required String type,
    String? topic, // Zapi sin thlahnak caah (Tahchunhnak: 'all_users')
    String? token, // Mi pakhat sin thlahnak caah (Uploader FCM Token)
    Map<String, dynamic>? extraData,
  }) async {
    try {
      final String serverToken = await _getAccessToken();
      final String endpoint = "https://fcm.googleapis.com/v1/projects/${_serviceAccountJson['project_id']}/messages:send";

      Map<String, String> stringData = {'type': type};
      if (extraData != null) {
        extraData.forEach((key, value) {
          stringData[key] = value.toString();
        });
      }

      // Mi zapi dah a si mi pakhat dah a si ti thleidannak
      Map<String, dynamic> target = {};
      if (topic != null) {
        target = {'topic': topic};
      } else if (token != null) {
        target = {'token': token};
      } else {
        return; // Topic asiloah Token pakhat tal a um hrimhrim a hau
      }

      final Map<String, dynamic> message = {
        'message': {
          ...target, // Hika ah topic asiloah token a lut lai
          'notification': {
            'title': title,
            'body': body,
          },
          'data': stringData,
        }
      };

      await http.post(
        Uri.parse(endpoint),
        headers: <String, String>{
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $serverToken',
        },
        body: jsonEncode(message),
      );
      print("Notification tlamtling tein thlah a si! Type: $type");
    } catch (e) {
      print("Notification palhnak: $e");
    }
  }

}