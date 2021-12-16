import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:kakao_flutter_sdk/kakao_flutter_sdk.dart';
import 'package:kakao_flutter_sdk_example/api_item.dart';
import 'package:kakao_flutter_sdk_example/debug_page.dart';
import 'package:kakao_flutter_sdk_example/friend_page.dart';
import 'package:kakao_flutter_sdk_example/log.dart';
import 'package:kakao_flutter_sdk_example/message_template.dart';
import 'package:kakao_flutter_sdk_example/picker_item.dart';
import 'package:kakao_flutter_sdk_example/server_phase.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'server_phase.dart';

const String tag = "KakaoSdkSample";
const Map<String, int> templateIds = {
  "customMemo": 67020,
  "customMessage": 67020,
};

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await _initializeSdk();

  SdkLog.i("${await KakaoSdk.origin}");

  runApp(MyApp());
}

Future _initializeSdk() async {
  KakaoPhase phase = await _getKakaoPhase();
  KakaoSdk.init(
    nativeAppKey: PhasedAppKey(phase).getAppKey(),
    serviceHosts: PhasedServerHosts(phase),
    loggingEnabled: true,
  );
}

Future<KakaoPhase> _getKakaoPhase() async {
  var prefs = await SharedPreferences.getInstance();
  var prevPhase = prefs.getString('KakaoPhase');
  print('$prevPhase');
  KakaoPhase phase;
  if (prevPhase == null) {
    phase = KakaoPhase.PRODUCTION;
  } else {
    if (prevPhase == "DEV") {
      phase = KakaoPhase.DEV;
    } else if (prevPhase == "SANDBOX") {
      phase = KakaoPhase.SANDBOX;
    } else if (prevPhase == "CBT") {
      phase = KakaoPhase.CBT;
    } else {
      phase = KakaoPhase.PRODUCTION;
    }
  }
  return phase;
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      initialRoute: '/',
      routes: {
        '/': (_) => MyPage(),
        '/debug': (_) => DebugPage(),
      },
    );
  }
}

class MyPage extends StatefulWidget {
  const MyPage({Key? key}) : super(key: key);

  @override
  _MyPageState createState() => _MyPageState();
}

class _MyPageState extends State<MyPage> {
  List<ApiItem> apiList = [];

  @override
  void initState() {
    super.initState();
    _initApiList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('SDK Sample'),
        actions: [
          GestureDetector(
            child: const Padding(
              padding: EdgeInsets.all(16.0),
              child: Center(
                child: Text('DEBUG'),
              ),
            ),
            onTap: () => Navigator.of(context).pushNamed('/debug'),
          )
        ],
      ),
      body: ListView.separated(
          itemBuilder: (context, index) {
            ApiItem item = apiList[index];
            bool isHeader = item.apiFunction == null;
            return ListTile(
              title: Text(
                item.label,
                style: TextStyle(
                    color: isHeader
                        ? Theme.of(context).primaryColor
                        : Colors.black),
              ),
              onTap: apiList[index].apiFunction,
            );
          },
          separatorBuilder: (context, index) => const Divider(),
          itemCount: apiList.length),
    );
  }

  _initApiList() {
    apiList = [
      ApiItem('User API'),
      ApiItem('isKakaoTalkLoginAvailable()', () async {
        // 카카오톡 설치여부 확인
        bool result = await isKakaoTalkInstalled();
        String msg = result ? '카카오톡으로 로그인 가능' : '카카오톡 미설치: 카카오계정으로 로그인 사용 권장';
        Log.i(context, tag, msg);
      }),
      ApiItem('loginWithKakaoTalk()', () async {
        // 카카오톡으로 로그인

        try {
          OAuthToken token = await UserApi.instance.loginWithKakaoTalk();
          Log.i(context, tag, '로그인 성공 ${token.accessToken}');
        } catch (e) {
          Log.e(context, tag, '로그인 실패', e);
        }
      }),
      ApiItem('certLoginWithKakaoTalk()', () async {
        // 카카오톡으로 인증서 로그인

        try {
          CertTokenInfo certTokenInfo =
              await UserApi.instance.certLoginWithKakaoTalk(state: "test");
          Log.i(context, tag,
              '로그인 성공 ${certTokenInfo.token.accessToken} ${certTokenInfo.txId}');
        } catch (e) {
          Log.e(context, tag, '로그인 실패', e);
        }
      }),
      ApiItem('loginWithKakaoAccount()', () async {
        // 카카오계정으로 로그인

        try {
          OAuthToken token = await UserApi.instance.loginWithKakaoAccount();
          Log.i(context, tag, '로그인 성공 ${token.accessToken}');
        } catch (e) {
          Log.e(context, tag, '로그인 실패', e);
        }
      }),
      ApiItem('loginWithKakaoAccount()', () async {
        // 카카오계정으로 로그인 - 재인증

        try {
          OAuthToken token = await UserApi.instance
              .loginWithKakaoAccount(prompts: [Prompt.login]);
          Log.i(context, tag, '로그인 성공 ${token.accessToken}');
        } catch (e) {
          Log.e(context, tag, '로그인 실패', e);
        }
      }),
      ApiItem('certLoginWithKakaoAccount()', () async {
        // 카카오계정으로 인증서 로그인

        try {
          CertTokenInfo certTokenInfo =
              await UserApi.instance.certLoginWithKakaoAccount(state: "test");
          Log.i(context, tag,
              '로그인 성공 ${certTokenInfo.token.accessToken} ${certTokenInfo.txId}');
        } catch (e) {
          Log.e(context, tag, '로그인 실패', e);
        }
      }),
      ApiItem('Combination Login', () async {
        // 로그인 조합 예제

        try {
          bool talkInstalled = await isKakaoTalkInstalled();

          // 카카오톡이 설치되어 있으면 카카오톡으로 로그인, 아니면 카카오계정으로 로그인
          OAuthToken token = talkInstalled
              ? await UserApi.instance.loginWithKakaoTalk()
              : await UserApi.instance.loginWithKakaoAccount();
          Log.i(context, tag, '로그인 성공 ${token.accessToken}');
        } catch (e) {
          Log.e(context, tag, '로그인 실패', e);
        }
      }),
      ApiItem('Combination Login (Verbose)', () async {
        // 로그인 조합 예제 + 상세한 에러처리 콜백
        // TODO: exception 정리
        // try {
        //   bool talkInstalled = await isKakaoTalkInstalled();
        //   카카오톡이 설치되어 있으면 카카오톡으로 로그인, 아니면 카카오계정으로 로그인
        //   OAuthToken token = talkInstalled
        //       ? await UserApi.instance.loginWithKakaoTalk()
        //       : await UserApi.instance.loginWithKakaoAccount();
        //   Log.i(context, tag, '로그인 성공 ${token.accessToken}');
        // } on KakaoClientException catch (error) {
        //   switch(error.) {
        //     is KakaoClient
        //   }
        //   Log.e(context, tag, '로그인 실패', error);
        // }
      }),
      ApiItem('me()', () async {
        // 사용자 정보 요청 (기본)

        try {
          User user = await UserApi.instance.me();
          Log.i(
              context,
              tag,
              '사용자 정보 요청 성공'
              '\n회원번호: ${user.id}'
              '\n이메일: ${user.kakaoAccount?.email}'
              '\n닉네임: ${user.kakaoAccount?.profile?.nickname}'
              '\n프로필사진: ${user.kakaoAccount?.profile?.thumbnailImageUrl}');
        } catch (e) {
          Log.e(context, tag, '사용자 정보 요청 실패', e);
        }
      }),
      ApiItem('me() - new scopes', () async {
        // 사용자 정보 요청 (추가 동의)

        // 사용자가 로그인 시 제3자 정보제공에 동의하지 않은 개인정보 항목 중 어떤 정보가 반드시 필요한 시나리오에 진입한다면
        // 다음과 같이 추가 동의를 받고 해당 정보를 획득할 수 있습니다.

        //  * 주의: 선택 동의항목은 사용자가 거부하더라도 서비스 이용에 지장이 없어야 합니다.

        // 추가 권한 요청 시나리오 예제

        User user;
        try {
          user = await UserApi.instance.me();
        } catch (e) {
          Log.e(context, tag, '사용자 정보 요청 실패', e);
          return;
        }

        List<String> scopes = [];

        if (user.kakaoAccount?.emailNeedsAgreement == true) {
          scopes.add('account_email');
        }
        if (user.kakaoAccount?.birthdayNeedsAgreement == true) {
          scopes.add("birthday");
        }
        if (user.kakaoAccount?.birthyearNeedsAgreement == true) {
          scopes.add("birthyear");
        }
        if (user.kakaoAccount?.ciNeedsAgreement == true) {
          scopes.add("account_ci");
        }
        if (user.kakaoAccount?.legalNameNeedsAgreement == true) {
          scopes.add("legal_name");
        }
        if (user.kakaoAccount?.legalBirthDateNeedsAgreement == true) {
          scopes.add("legal_birth_date");
        }
        if (user.kakaoAccount?.legalGenderNeedsAgreement == true) {
          scopes.add("legal_gender");
        }
        if (user.kakaoAccount?.phoneNumberNeedsAgreement == true) {
          scopes.add("phone_number");
        }
        if (user.kakaoAccount?.profileNeedsAgreement == true) {
          scopes.add("profile");
        }
        if (user.kakaoAccount?.ageRangeNeedsAgreement == true) {
          scopes.add("age_range");
        }

        if (scopes.length > 0) {
          Log.d(context, tag, '사용자에게 추가 동의를 받아야 합니다.');

          OAuthToken token;
          try {
            token = await UserApi.instance.loginWithNewScopes(scopes);
            Log.i(context, tag, 'allowed scopes: ${token.scopes}');
          } catch (e) {
            Log.e(context, tag, "사용자 추가 동의 실패", e);
            return;
          }

          try {
            // 사용자 정보 재요청
            User user = await UserApi.instance.me();
            Log.i(
                context,
                tag,
                '사용자 정보 요청 성공'
                '\n회원번호: ${user.id}'
                '\n이메일: ${user.kakaoAccount?.email}'
                '\n닉네임: ${user.kakaoAccount?.profile?.nickname}'
                '\n프로필사진: ${user.kakaoAccount?.profile?.thumbnailImageUrl}');
          } catch (e) {
            Log.e(context, tag, '사용자 정보 요청 실패', e);
          }
        }
      }),
      ApiItem('signup()', () async {
        try {
          await UserApi.instance.signup();
          Log.i(context, tag, 'signup 성공');
        } catch (e) {
          Log.e(context, tag, 'signup 실패', e);
        }
      }),
      ApiItem('scopes()', () async {
        // 동의 항목 확인하기

        try {
          ScopeInfo scopeInfo = await UserApi.instance.scopes();
          Log.i(
              context, tag, '동의 정보 확인 성공\n현재 가지고 있는 동의 항목 ${scopeInfo.scopes}');
        } catch (e) {
          Log.e(context, tag, '동의 정보 확인 실패', e);
        }
      }),
      ApiItem('scopes() - optional', () async {
        // 특정 동의 항목 확인하기

        List<String> scopes = ['account_email', 'friends'];
        try {
          ScopeInfo scopeInfo = await UserApi.instance.scopes(scopes: scopes);
          Log.i(
              context, tag, '동의 정보 확인 성공\n현재 가지고 있는 동의 항목 ${scopeInfo.scopes}');
        } catch (e) {
          Log.e(context, tag, '동의 정보 확인 실패', e);
        }
      }),
      ApiItem('revokeScopes()', () async {
        List<String> scopes = ['account_email', 'legal_birth_date', 'friends'];
        try {
          ScopeInfo scopeInfo = await UserApi.instance.revokeScopes(scopes);
          Log.i(context, tag, '동의 철회 성공\n현재 가지고 있는 동의 항목 ${scopeInfo.scopes}');
        } catch (e) {
          Log.e(context, tag, '동의 철회 실패', e);
        }
      }),
      ApiItem('accessTokenInfo()', () async {
        // 토큰 정보 보기

        try {
          AccessTokenInfo tokenInfo = await UserApi.instance.accessTokenInfo();
          Log.i(context, tag,
              '토큰 정보 보기 성공\n회원정보: ${tokenInfo.id}\n만료시간: ${tokenInfo.expiresIn} 초');
        } catch (e) {
          Log.e(context, tag, '동의 철회 실패', e);
        }
      }),
      ApiItem('updateProfile() - nickname', () async {
        // 사용자 정보 저장

        try {
          // 변경할 내용
          Map<String, String> properties = {'nickname': "${DateTime.now()}"};
          await UserApi.instance.updateProfile(properties);
          Log.i(context, tag, '사용자 정보 저장 성공');
        } catch (e) {
          Log.e(context, tag, '사용자 정보 저장 실패', e);
        }
      }),
      ApiItem('shippingAddresses()', () async {
        // 배송지 조회 (추가 동의)

        UserShippingAddresses userShippingAddress;
        try {
          userShippingAddress = await UserApi.instance.shippingAddresses();
        } catch (e) {
          Log.e(context, tag, '배송지 조회 실패', e);
          return;
        }

        if (userShippingAddress.shippingAddresses != null) {
          Log.i(context, tag,
              '배송지 조회 성공\n회원번호: ${userShippingAddress.userId}\n배송지: \n${userShippingAddress.shippingAddresses?.join('\n')}');
        } else if (!userShippingAddress.needsAgreement) {
          Log.e(context, tag,
              '사용자 계정에 배송지 없음. 꼭 필요하다면 동의항목 설정에서 수집 기능을 활성화 해보세요.');
        } else if (userShippingAddress.needsAgreement) {
          Log.d(context, tag, '사용자에게 배송지 제공 동의를 받아야 합니다.');

          List<String> scopes = ['shipping_address'];

          OAuthToken token;
          try {
            // 사용자에게 배송지 제공 동의 요청
            token = await UserApi.instance.loginWithNewScopes(scopes);
            Log.d(context, tag, 'allowed scopes: ${token.scopes}');
          } catch (e) {
            Log.e(context, tag, '배송지 제공 동의 실패', e);
          }

          try {
            UserShippingAddresses userShippingAddresses =
                await UserApi.instance.shippingAddresses();
            Log.i(context, tag,
                '배송지 조회 성공\n회원번호: ${userShippingAddresses.userId}\n${userShippingAddresses.shippingAddresses?.join('\n')}');
          } catch (e) {
            Log.e(context, tag, '배송지 조회 실패', e);
          }
        }
      }),
      ApiItem('serviceTerms()', () async {
        // 동의한 약관 확인하기

        try {
          UserServiceTerms userServiceTerms =
              await UserApi.instance.serviceTerms();
          Log.i(context, tag,
              '동의한 약관 확인하기 성공\n회원정보: ${userServiceTerms.userId}\n동의한 약관: \n${userServiceTerms.allowedServiceTerms?.join('\n')}');
        } catch (e) {
          Log.e(context, tag, '동의한 약관 확인하기 실패', e);
        }
      }),
      ApiItem('logout()', () async {
        // 로그아웃

        try {
          await UserApi.instance.logout();
          Log.i(context, tag, '로그아웃 성공. SDK에서 토큰 삭제 됨');
        } catch (e) {
          Log.e(context, tag, '로그아웃 실패. SDK에서 토큰 삭제 됨', e);
        }
      }),
      ApiItem('unlink()', () async {
        // 연결 끊기

        try {
          await UserApi.instance.unlink();
          Log.i(context, tag, '연결 끊기 성공. SDK에서 토큰 삭제 됨');
        } catch (e) {
          Log.e(context, tag, '연결 끊기 실패', e);
        }
      }),
      ApiItem('KakaoTalk API'),
      ApiItem('profile()', () async {
        // 카카오톡 프로필 받기

        try {
          TalkProfile profile = await TalkApi.instance.profile();
          Log.i(context, tag,
              '카카오톡 프로필 받기 성공\n닉네임: ${profile.nickname}\n프로필사진: ${profile.thumbnailUrl}\n국가코드: ${profile.countryISO}');
        } catch (e) {
          Log.e(context, tag, '카카오톡 프로필 받기 실패', e);
        }
      }),
      ApiItem('sendCustomMemo()', () async {
        // 커스텀 템플릿으로 나에게 보내기

        // 메시지 템플릿 아이디
        // * 만들기 가이드: https://developers.kakao.com/docs/latest/ko/message/message-template
        int templateId = templateIds['customMessage']!;

        try {
          await TalkApi.instance.customMemo(templateId);
          Log.i(context, tag, '나에게 보내기 성공');
        } catch (e) {
          Log.e(context, tag, '나에게 보내기 실패', e);
        }
      }),
      ApiItem('sendDefaultMemo()', () async {
        try {
          // 디폴트 템플릿으로 나에게 보내기 - Feed
          await TalkApi.instance.defaultMemo(defaultFeed);
          Log.i(context, tag, '나에게 보내기 성공');
        } catch (e) {
          Log.e(context, tag, '나에게 보내기 실패', e);
        }
      }),
      ApiItem('sendScrapMemo()', () async {
        // 스크랩 템플릿으로 나에게 보내기

        // 공유할 웹페이지 URL
        //  * 주의: 개발자사이트 Web 플랫폼 설정에 공유할 URL의 도메인이 등록되어 있어야 합니다.
        String url = 'https://developers.kakao.com';

        try {
          await TalkApi.instance.scrapMemo(url);
          Log.i(context, tag, '나에게 보내기 성공');
        } catch (e) {
          Log.e(context, tag, '나에게 보내기 실패', e);
        }
      }),
      ApiItem('friends()', () async {
        // 카카오톡 친구 목록 받기 (기본)

        try {
          Friends friends = await TalkApi.instance.friends();
          Log.i(context, tag,
              '카카오톡 친구 목록 받기 성공\n${friends.elements?.join('\n')}');

          // 친구의 UUID 로 메시지 보내기 가능
        } catch (e) {
          Log.e(context, tag, '카카오톡 친구 목록 받기 실패', e);
        }
      }),
      ApiItem("friends(order:) - desc", () async {
        // 카카오톡 친구 목록 받기 (파라미터)

        try {
          // 내림차순으로 받기
          Friends friends = await TalkApi.instance.friends(order: "desc");
          Log.i(context, tag,
              '카카오톡 친구 목록 받기 성공\n${friends.elements?.join('\n')}');

          // 친구의 UUID 로 메시지 보내기 가능
        } catch (e) {
          Log.e(context, tag, '카카오톡 친구 목록 받기 실패', e);
        }
      }),
      ApiItem('friends(context:) - recursive', () async {
        // TODO: FriendContext 추가
      }),
      ApiItem('sendCustomMessage()', () async {
        // 커스텀 템플릿으로 친구에게 메시지 보내기

        Friends friends;
        try {
          // 카카오톡 친구 목록 받기
          friends = await TalkApi.instance.friends();
        } catch (e) {
          Log.e(context, tag, '카카오톡 친구 목록 받기 실패', e);
          return;
        }

        if (friends.elements == null) {
          return;
        }

        if (friends.elements!.isEmpty) {
          Log.e(context, tag, '메시지 보낼 친구가 없습니다');
        } else {
          // 서비스에 상황에 맞게 메시지 보낼 친구의 UUID 를 가져오세요.
          // 이 샘플에서는 친구 목록을 화면에 보여주고 체크박스로 선택된 친구들의 UUID 를 수집하도록 구현했습니다.
          List<String> selectedItems = await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => FriendPage(
                items: friends.elements!
                    .map((friend) => PickerItem(
                        friend.uuid,
                        friend.profileNickname ?? '',
                        friend.profileThumbnailImage))
                    .toList(),
              ),
            ),
          );

          if (selectedItems.isEmpty) {
            return;
          }
          Log.d(context, tag, '선택된 친구:\n${selectedItems.join('\n')}');

          // 메시지 보낼 친구의 UUID 목록
          List<String> receiverUuids = selectedItems;

          // 메시지 템플릿 아이디
          // * 만들기 가이드: https://developers.kakao.com/docs/latest/ko/message/message-template
          int templateId = templateIds['customMessage']!;

          try {
            // 메시지 보내기
            MessageSendResult result =
                await TalkApi.instance.customMessage(receiverUuids, templateId);
            Log.i(context, tag, '메시지 보내기 성공 ${result.successfulReceiverUuids}');

            if (result.failureInfos != null) {
              Log.d(context, tag,
                  '메시지 보내기에 일부 성공했으나, 일부 대상에게는 실패 \n${result.failureInfos}');
            }
          } catch (e) {
            Log.e(context, tag, '메시지 보내기 실패', e);
          }
        }
      }),
      ApiItem('sendDefaultMessage()', () async {
        // 디폴트 템플릿으로 친구에게 메시지 보내기 - Feed

        Friends friends;
        try {
          // 카카오톡 친구 목록 받기
          friends = await TalkApi.instance.friends();
        } catch (e) {
          Log.e(context, tag, '카카오톡 친구 목록 받기 실패', e);
          return;
        }

        if (friends.elements == null) {
          return;
        }

        if (friends.elements!.isEmpty) {
          Log.e(context, tag, '메시지 보낼 친구가 없습니다');
        } else {
          // 서비스에 상황에 맞게 메시지 보낼 친구의 UUID 를 가져오세요.
          // 이 샘플에서는 친구 목록을 화면에 보여주고 체크박스로 선택된 친구들의 UUID 를 수집하도록 구현했습니다.
          List<String> selectedItems = await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => FriendPage(
                items: friends.elements!
                    .map((friend) => PickerItem(
                        friend.uuid,
                        friend.profileNickname ?? '',
                        friend.profileThumbnailImage))
                    .toList(),
              ),
            ),
          );

          if (selectedItems.isEmpty) {
            return;
          }
          Log.d(context, tag, '선택된 친구:\n${selectedItems.join('\n')}');

          // 메시지 보낼 친구의 UUID 목록
          List<String> receiverUuids = selectedItems;

          // 메시지 템플릿 아이디
          // * 만들기 가이드: https://developers.kakao.com/docs/latest/ko/message/message-template
          int templateId = templateIds['customMessage']!;

          try {
            // 메시지 보내기
            MessageSendResult result =
                await TalkApi.instance.customMessage(receiverUuids, templateId);
            Log.i(context, tag, '메시지 보내기 성공 ${result.successfulReceiverUuids}');

            if (result.failureInfos != null) {
              Log.d(context, tag,
                  '메시지 보내기에 일부 성공했으나, 일부 대상에게는 실패 \n${result.failureInfos}');
            }
          } catch (e) {
            Log.e(context, tag, '메시지 보내기 실패', e);
          }
        }
      }),
      ApiItem('sendScrapMessage()', () async {
        // 스크랩 템플릿으로 친구에게 메시지 보내기

        Friends friends;
        try {
          // 카카오톡 친구 목록 받기
          friends = await TalkApi.instance.friends();
        } catch (e) {
          Log.e(context, tag, '카카오톡 친구 목록 받기 실패', e);
          return;
        }

        if (friends.elements == null) {
          return;
        }

        if (friends.elements!.isEmpty) {
          Log.e(context, tag, '메시지 보낼 친구가 없습니다');
        } else {
          // 서비스에 상황에 맞게 메시지 보낼 친구의 UUID 를 가져오세요.
          // 이 샘플에서는 친구 목록을 화면에 보여주고 체크박스로 선택된 친구들의 UUID 를 수집하도록 구현했습니다.
          List<String> selectedItems = await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => FriendPage(
                items: friends.elements!
                    .map((friend) => PickerItem(
                        friend.uuid,
                        friend.profileNickname ?? '',
                        friend.profileThumbnailImage))
                    .toList(),
              ),
            ),
          );

          if (selectedItems.isEmpty) {
            return;
          }
          Log.d(context, tag, '선택된 친구:\n${selectedItems.join('\n')}');

          // 메시지 보낼 친구의 UUID 목록
          List<String> receiverUuids = selectedItems;

          // 공유할 웹페이지 URL
          //  * 주의: 개발자사이트 Web 플랫폼 설정에 공유할 URL의 도메인이 등록되어 있어야 합니다.
          String url = "https://developers.kakao.com";

          try {
            // 메시지 보내기
            MessageSendResult result =
                await TalkApi.instance.scrapMessage(receiverUuids, url);
            Log.i(context, tag, '메시지 보내기 성공 ${result.successfulReceiverUuids}');

            if (result.failureInfos != null) {
              Log.d(context, tag,
                  '메시지 보내기에 일부 성공했으나, 일부 대상에게는 실패 \n${result.failureInfos}');
            }
          } catch (e) {
            Log.e(context, tag, '메시지 보내기 실패', e);
          }
        }
      }),
      ApiItem('channels()', () async {
        // 카카오톡 채널 관계 확인하기

        try {
          Channels relations = await TalkApi.instance.plusFriends();
          Log.i(context, tag, '채널 관계 확인 성공\n${relations.channels}');
        } catch (e) {
          Log.e(context, tag, '채널 관계 확인 실패', e);
        }
      }),
      ApiItem('addChannelUrl()', () async {
        // 카카오톡 채널 추가하기 URL
        Uri url = await TalkApi.instance.channelAddUrl('_ZeUTxl');

        try {
          // 디바이스 브라우저 열기
          await launchBrowserTab(url);
        } catch (e) {
          Log.e(context, tag, 'Error', e);
        }
      }),
      ApiItem('channelChatUrl()', () async {
        // 카카오톡 채널 채팅 URL
        Uri url = await TalkApi.instance.channelChatUrl('_ZeUTxl');

        try {
          // 디바이스 브라우저 열기
          await launchBrowserTab(url);
        } catch (e) {
          Log.e(context, tag, '인터넷 브라우저 미설치: 인터넷 브라우저를 설치해주세요', e);
        }
      }),
    ];
  }
}
