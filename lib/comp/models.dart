class OrganizationSubmission {
  final String orgName;
  final String orgType;
  final DateTime submissionDate;
  final String fileName;
  final double totalEmissions;
  final double emissionLimit;
  bool approved;
  double? fine;

  OrganizationSubmission({
    required this.orgName,
    required this.orgType,
    required this.submissionDate,
    required this.fileName,
    required this.totalEmissions,
    required this.emissionLimit,
    this.approved = false,
    this.fine,
  });
}

class SubmissionManager {
  static final SubmissionManager _instance = SubmissionManager._internal();
  factory SubmissionManager() => _instance;
  SubmissionManager._internal();

  final List<OrganizationSubmission> _submissions = [];

  void addSubmission(OrganizationSubmission submission) {
    _submissions.add(submission);
  }

  List<OrganizationSubmission> getSubmissions() => _submissions;
}
