import 'package:kakao_flutter_sdk_common/common.dart';
import 'package:kakao_flutter_sdk_navi/src/model/location.dart';
import 'package:kakao_flutter_sdk_navi/src/model/navi_option.dart';

part 'kakao_navi_params.g.dart';

/// @nodoc
@JsonSerializable(
    fieldRename: FieldRename.snake, includeIfNull: false, explicitToJson: true)
class KakaoNaviParams {
  final Location destination;
  final NaviOption? option;
  final List<Location>? viaList;

  KakaoNaviParams(this.destination, {this.option, this.viaList});

  Map<String, dynamic> toJson() => _$KakaoNaviParamsToJson(this);

  factory KakaoNaviParams.fromJson(Map<String, dynamic> json) =>
      _$KakaoNaviParamsFromJson(json);
}
