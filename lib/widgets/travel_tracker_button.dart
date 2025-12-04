import 'package:flutter/material.dart';
import '../services/travel_tracker_service.dart';

/// 여행 기록 시작/중지 버튼 위젯
class TravelTrackerButton extends StatefulWidget {
  const TravelTrackerButton({super.key});

  @override
  State<TravelTrackerButton> createState() => _TravelTrackerButtonState();
}

class _TravelTrackerButtonState extends State<TravelTrackerButton> {
  final TravelTrackerService _trackerService = TravelTrackerService();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _trackerService.addListener(_onTrackerStateChanged);
  }

  @override
  void dispose() {
    _trackerService.removeListener(_onTrackerStateChanged);
    super.dispose();
  }

  void _onTrackerStateChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _toggleTracking() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      if (_trackerService.isTracking) {
        // 여행 기록 중지
        await _trackerService.stopTracking();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('여행 기록이 종료되었습니다.'),
              backgroundColor: Colors.grey,
            ),
          );
        }
      } else {
        // 여행 기록 시작
        await _trackerService.startTracking();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('여행 기록이 시작되었습니다! 🎉'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('오류: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isTracking = _trackerService.isTracking;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: ElevatedButton(
        onPressed: _isLoading ? null : _toggleTracking,
        style: ElevatedButton.styleFrom(
          backgroundColor: isTracking ? Colors.red[400] : Colors.blue[400],
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: isTracking ? 4 : 2,
        ),
        child: _isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    isTracking ? Icons.stop_circle : Icons.location_on,
                    size: 24,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    isTracking ? '여행 기록 중...' : '여행 기록 시작하기',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (isTracking) ...[
                    const SizedBox(width: 10),
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.white.withOpacity(0.5),
                            blurRadius: 8,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
      ),
    );
  }
}

/// 작은 상태 표시 위젯 (다른 화면에서 사용)
class TravelTrackerStatusIndicator extends StatefulWidget {
  const TravelTrackerStatusIndicator({super.key});

  @override
  State<TravelTrackerStatusIndicator> createState() =>
      _TravelTrackerStatusIndicatorState();
}

class _TravelTrackerStatusIndicatorState
    extends State<TravelTrackerStatusIndicator> {
  final TravelTrackerService _trackerService = TravelTrackerService();

  @override
  void initState() {
    super.initState();
    _trackerService.addListener(_onTrackerStateChanged);
  }

  @override
  void dispose() {
    _trackerService.removeListener(_onTrackerStateChanged);
    super.dispose();
  }

  void _onTrackerStateChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_trackerService.isTracking) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.red[400],
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          const Text(
            '기록 중',
            style: TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
