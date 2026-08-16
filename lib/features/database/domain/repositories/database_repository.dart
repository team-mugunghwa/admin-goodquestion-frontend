import '../entities/db_schema.dart';

/// DB 구조와 값 조회. **읽기만 합니다.**
///
/// 쓰기 메서드를 두지 않은 것은 실수 방지가 아니라 설계입니다. 관리자 콘솔은
/// 사용자 서비스와 같은 운영 DB 를 보므로, 이 화면에서 값을 고칠 수 있게 되면
/// 서비스 규칙을 건너뛴 데이터가 들어갑니다. 값을 바꿔야 한다면 그 도메인의
/// 관리 화면(이야기 관리, 사용자 관리)을 씁니다.
abstract class DatabaseRepository {
  Future<List<DbTableSummary>> getTables();

  Future<DbTableDetail> getTable(String tableName);

  Future<DbRowPage> getRows({
    required String tableName,
    int page = 0,
    int size = 50,
    String? sortColumn,
    String? sortDirection,
    String? filterColumn,
    String? keyword,
  });
}
