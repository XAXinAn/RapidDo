import 'dart:io';
import 'package:dio/dio.dart';
import 'package:jisu_calendar/common/constants/api_constants.dart';
import 'package:jisu_calendar/common/models/api_response.dart';
import 'package:jisu_calendar/services/api_service.dart';

/// 头像服务
/// 基于后端接口文档 /api/avatar
class AvatarService {
  final ApiService _apiService = ApiService();

  /// 上传头像
  /// POST /api/avatar/upload
  /// 自动删除旧头像
  /// 
  /// [file] 头像文件
  /// [userId] 用户ID
  /// 
  /// 文件限制:
  /// - 最大大小: 5MB
  /// - 允许格式: jpg, jpeg, png, webp
  Future<ApiResponse<String>> uploadAvatar({
    required File file,
    required String userId,
  }) async {
    try {
      // 检查文件大小 (5MB限制)
      final fileSize = await file.length();
      if (fileSize > 5 * 1024 * 1024) {
        return ApiResponse<String>(
          success: false,
          message: '文件大小不能超过5MB',
          statusCode: 413,
        );
      }

      // 检查文件扩展名
      final extension = file.path.split('.').last.toLowerCase();
      if (!['jpg', 'jpeg', 'png', 'webp'].contains(extension)) {
        return ApiResponse<String>(
          success: false,
          message: '不支持的文件类型，仅支持 jpg, jpeg, png, webp',
          statusCode: 400,
        );
      }

      // 构建 FormData
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(
          file.path,
          filename: '${userId}_${DateTime.now().millisecondsSinceEpoch}.$extension',
        ),
        'userId': userId,
      });

      // 发起上传请求
      final response = await _apiService.post(
        ApiConstants.avatarUpload,
        data: formData,
      );

      if (response.success && response.data != null) {
        final data = response.data as Map<String, dynamic>;
        final avatarUrl = data['avatarUrl'] as String?;
        
        if (avatarUrl != null) {
          return ApiResponse<String>(
            success: true,
            message: response.message ?? '上传成功',
            data: avatarUrl,
            statusCode: response.statusCode,
          );
        }
      }

      return ApiResponse<String>(
        success: false,
        message: response.message ?? '上传失败',
        statusCode: response.statusCode,
      );
    } catch (e) {
      return ApiResponse<String>(
        success: false,
        message: '上传头像失败: $e',
      );
    }
  }

  /// 删除头像
  /// DELETE /api/avatar/{userId}
  /// 恢复为默认头像
  Future<ApiResponse<void>> deleteAvatar(String userId) async {
    try {
      final response = await _apiService.delete(
        ApiConstants.avatarDelete(userId),
      );

      return ApiResponse<void>(
        success: response.success,
        message: response.message ?? (response.success ? '删除成功' : '删除失败'),
        statusCode: response.statusCode,
      );
    } catch (e) {
      return ApiResponse<void>(
        success: false,
        message: '删除头像失败: $e',
      );
    }
  }

  /// 获取头像完整 URL
  /// 如果是相对路径，补全 baseUrl
  /// 处理 DiceBear SVG 格式问题
  String getAvatarUrl(String? avatar) {
    if (avatar == null || avatar.isEmpty) {
      // 使用 PNG 格式替代 SVG (Flutter NetworkImage 不支持 SVG)
      return 'https://api.dicebear.com/7.x/initials/png?seed=User&size=128';
    }
    
    // 如果是 DiceBear 的 SVG URL，转换为 PNG 格式
    if (avatar.contains('api.dicebear.com') && avatar.contains('/svg')) {
      // 将 /svg 替换为 /png 并添加 size 参数
      String pngUrl = avatar.replaceAll('/svg', '/png');
      if (!pngUrl.contains('size=')) {
        pngUrl += pngUrl.contains('?') ? '&size=128' : '?size=128';
      }
      return pngUrl;
    }
    
    // 如果已经是完整 URL，直接返回
    if (avatar.startsWith('http://') || avatar.startsWith('https://')) {
      return avatar;
    }
    
    // 如果是相对路径，补全 baseUrl
    return '${ApiConstants.baseUrl}$avatar';
  }

  /// 检查头像是否为默认头像
  bool isDefaultAvatar(String? avatar) {
    if (avatar == null || avatar.isEmpty) return true;
    return avatar.contains('api.dicebear.com');
  }
}
