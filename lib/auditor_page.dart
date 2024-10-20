import 'package:flutter/material.dart';
import './comp/models.dart';

// Assuming OrganizationSubmission and SubmissionManager are already defined

class AuditorPage extends StatefulWidget {
  @override
  _AuditorPageState createState() => _AuditorPageState();
}

class _AuditorPageState extends State<AuditorPage> {
  List<OrganizationSubmission> _submissions = [];

  @override
  void initState() {
    super.initState();
    _loadSubmissions();
  }

  // Load submissions from SubmissionManager
  void _loadSubmissions() {
    setState(() {
      _submissions = SubmissionManager().getSubmissions();
    });
  }

  // View submission details
  void _viewSubmissionDetails(BuildContext context, OrganizationSubmission submission) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Submission Details'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Organization: ${submission.orgName}', style: TextStyle(fontWeight: FontWeight.bold)),
                SizedBox(height: 8),
                Text('Type: ${submission.orgType}'),
                Text('File: ${submission.fileName}'),
                Text('Total Emissions: ${submission.totalEmissions.toStringAsFixed(2)} tons CO2'),
                Text('Emission Limit: ${submission.emissionLimit.toStringAsFixed(2)} tons CO2'),
                Text('Status: ${submission.totalEmissions > submission.emissionLimit ? "Exceeded" : "Within Limit"}'),
                Text('Submission Date: ${submission.submissionDate.toString()}'),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Close'),
            ),
          ],
        );
      },
    );
  }

  // Fine the organization
  void _fineOrganization(BuildContext context, OrganizationSubmission submission) {
    TextEditingController fineController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Fine Organization'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Emissions: ${submission.totalEmissions.toStringAsFixed(2)} / ${submission.emissionLimit.toStringAsFixed(2)} tons CO2',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 16),
              TextField(
                controller: fineController,
                decoration: InputDecoration(
                  labelText: 'Fine Amount',
                  prefixText: '\$',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                setState(() {
                  submission.fine = double.tryParse(fineController.text) ?? 0.0;
                });
                Navigator.of(context).pop();
              },
              child: Text('Submit Fine'),
            ),
          ],
        );
      },
    );
  }

  // Approve submission
  void _approveSubmission(OrganizationSubmission submission) {
    setState(() {
      submission.approved = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Auditor Page'),
        centerTitle: true,
      ),
      body: _submissions.isEmpty
          ? Center(
              child: Text('No submissions yet', style: TextStyle(fontSize: 20)),
            )
          : ListView.builder(
              itemCount: _submissions.length,
              itemBuilder: (context, index) {
                var submission = _submissions[index];
                return Card(
                  margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                  color: submission.approved ? Colors.green[100] : Colors.white,
                  elevation: 4,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ListTile(
                          title: Text(
                            submission.orgName,
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Type: ${submission.orgType}'),
                              Text('Submitted: ${submission.submissionDate.toString()}'),
                              SizedBox(height: 4),
                              Text(
                                'Emissions: ${submission.totalEmissions.toStringAsFixed(2)} / ${submission.emissionLimit.toStringAsFixed(2)} tons CO2',
                                style: TextStyle(
                                  color: submission.totalEmissions > submission.emissionLimit ? Colors.red : Colors.green,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              if (submission.fine != null)
                                Text(
                                  'Fine: \$${submission.fine!.toStringAsFixed(2)}',
                                  style: TextStyle(color: Colors.red),
                                ),
                            ],
                          ),
                          trailing: ElevatedButton(
                            onPressed: () => _viewSubmissionDetails(context, submission),
                            child: Text('View Details'),
                          ),
                        ),
                        ButtonBar(
                          alignment: MainAxisAlignment.end,
                          children: [
                            if (!submission.approved)
                              ElevatedButton(
                                onPressed: () => _approveSubmission(submission),
                                child: Text('Approve'),
                              ),
                            ElevatedButton(
                              onPressed: () => _fineOrganization(context, submission),
                              child: Text('Fine'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
