import 'package:jisu_calendar/common/constants/api_constants.dart';
import 'package:jisu_calendar/common/models/api_response.dart';
import 'package:jisu_calendar/models/schedule.dart';
import 'package:jisu_calendar/services/api_service.dart';
import 'package:jisu_calendar/services/auth_service.dart';

/// 日程服务
/// 基于后端接口文档 /api/schedules
class ScheduleService {
  final ApiService _apiService = ApiService();
  final AuthService _authService = AuthService();

  /// 获取指定月份的日程
  /// GET /api/schedules?year={year}&month={month}&userId={userId}
  Future<ApiResponse<List<Schedule>>> getSchedulesByMonth({
    required int year,
    required int month,
  }) async {
    try {
      final userId = await _authService.getCurrentUserId();
      if (userId == null) {
        return ApiResponse<List<Schedule>>(
          success: false,
          message: '未登录',
        );
      }

      final response = await _apiService.get(
        ApiConstants.schedulesQuery(year: year, month: month, userId: userId),
      );

      if (response.success && response.data != null) {
        final List<dynamic> dataList = response.data as List<dynamic>;
        final schedules = dataList
            .map((json) => Schedule.fromJson(json as Map<String, dynamic>))
            .toList();
        
        return ApiResponse<List<Schedule>>(
          success: true,
          message: response.message,
          data: schedules,
          statusCode: response.statusCode,
        );
      }

      return ApiResponse<List<Schedule>>(
        success: false,
        message: response.message ?? '获取日程失败',
        statusCode: response.statusCode,
      );
    } catch (e) {
      return ApiResponse<List<Schedule>>(
        success: false,
        message: '获取日程失败: $e',
      );
    }
  }

  /// 按日期范围获取日程
  Future<ApiResponse<List<Schedule>>> getSchedulesByDateRange({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final userId = await _authService.getCurrentUserId();
      if (userId == null) {
        return ApiResponse<List<Schedule>>(
          success: false,
          message: '未登录',
        );
      }

      final startStr = _formatDate(startDate);
      final endStr = _formatDate(endDate);

      final response = await _apiService.get(
        ApiConstants.schedulesDateRange(
          startDate: startStr,
          endDate: endStr,
          userId: userId,
        ),
      );

      if (response.success && response.data != null) {
        final List<dynamic> dataList = response.data as List<dynamic>;
        final schedules = dataList
            .map((json) => Schedule.fromJson(json as Map<String, dynamic>))
            .toList();
        
        return ApiResponse<List<Schedule>>(
          success: true,
          message: response.message,
          data: schedules,
          statusCode: response.statusCode,
        );
      }

      return ApiResponse<List<Schedule>>(
        success: false,
        message: response.message ?? '获取日程失败',
        statusCode: response.statusCode,
      );
    } catch (e) {
      return ApiResponse<List<Schedule>>(
        success: false,
        message: '获取日程失败: $e',
      );
    }
  }

  /// 创建日程
  /// POST /api/schedules
  Future<ApiResponse<Schedule>> createSchedule(Schedule schedule) async {
    try {
      final userId = await _authService.getCurrentUserId();
      if (userId == null) {
        return ApiResponse<Schedule>(
          success: false,
          message: '未登录',
        );
      }

      // 构建请求体，添加 userId
      final requestData = schedule.toJson();
      requestData['userId'] = userId;
      
      // 调试日志 - 检查发送的数据
      print('=== 创建日程请求数据 ===');
      print('颜色值: ${requestData['color']}');
      print('完整数据: $requestData');

      final response = await _apiService.post(
        ApiConstants.schedules,
        data: requestData,
      );

      if (response.success && response.data != null) {
        final createdSchedule = Schedule.fromJson(response.data as Map<String, dynamic>);
        return ApiResponse<Schedule>(
          success: true,
          message: response.message ?? '创建成功',
          data: createdSchedule,
          statusCode: response.statusCode,
        );
      }

      return ApiResponse<Schedule>(
        success: false,
        message: response.message ?? '创建日程失败',
        statusCode: response.statusCode,
      );
    } catch (e) {
      return ApiResponse<Schedule>(
        success: false,
        message: '创建日程失败: $e',
      );
    }
  }

  /// 更新日程
  /// PUT /api/schedules/{scheduleId}
  Future<ApiResponse<Schedule>> updateSchedule(Schedule schedule) async {
    try {
      final response = await _apiService.put(
        ApiConstants.scheduleById(schedule.id),
        data: schedule.toJson(),
      );

      if (response.success && response.data != null) {
        final updatedSchedule = Schedule.fromJson(response.data as Map<String, dynamic>);
        return ApiResponse<Schedule>(
          success: true,
          message: response.message ?? '更新成功',
          data: updatedSchedule,
          statusCode: response.statusCode,
        );
      }

      return ApiResponse<Schedule>(
        success: false,
        message: response.message ?? '更新日程失败',
        statusCode: response.statusCode,
      );
    } catch (e) {
      return ApiResponse<Schedule>(
        success: false,
        message: '更新日程失败: $e',
      );
    }
  }

  /// 删除日程
  /// DELETE /api/schedules/{scheduleId}
  Future<ApiResponse<void>> deleteSchedule(String scheduleId) async {
    try {
      final response = await _apiService.delete(
        ApiConstants.scheduleById(scheduleId),
      );

      return ApiResponse<void>(
        success: response.success,
        message: response.message ?? (response.success ? '删除成功' : '删除失败'),
        statusCode: response.statusCode,
      );
    } catch (e) {
      return ApiResponse<void>(
        success: false,
        message: '删除日程失败: $e',
      );
    }
  }

  /// 格式化日期为 yyyy-MM-dd
  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}
