import '../entity/department.dart';

 String getDepartmentDisplay(
    String departmentEng,
    List<Department> departmentList,
  ) {
    final searchValue = departmentEng.trim().toLowerCase();

    for (final department in departmentList) {
      if (department.value.trim().toLowerCase() == searchValue) {
        final label = department.label.trim();

        return label.isNotEmpty ? label : departmentEng;
      }
    }

    // ถ้าจับคู่ไม่ได้ ให้คืนค่าเดิม
    return departmentEng;
  }