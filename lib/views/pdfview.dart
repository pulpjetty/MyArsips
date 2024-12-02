import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

class PdfViewPage extends StatefulWidget {
  final String url;
  final String title;

  PdfViewPage({required this.url, required this.title});

  @override
  _PdfViewPage createState() => _PdfViewPage();
}

class _PdfViewPage extends State<PdfViewPage> {
  bool loading = true;
  String? localPath;

  // Function to download the PDF file from the URL
  Future<void> downloadPdf() async {
    try {
      // Send HTTP GET request to the PDF URL
      final response = await http.get(Uri.parse(widget.url));

      if (response.statusCode == 200) {
        // Get the temporary directory where we will store the downloaded file
        var dir = await getTemporaryDirectory();
        String filePath = "${dir.path}/downloaded_pdf.pdf";

        // Write the response bytes to a file
        File(filePath).writeAsBytesSync(response.bodyBytes);

        setState(() {
          localPath = filePath;
          loading = false;
        });
      } else {
        throw Exception('Failed to download PDF');
      }
    } catch (e) {
      setState(() {
        loading = false;
      });
      print("Error downloading PDF: $e");
    }
  }

  @override
  void initState() {
    super.initState();
    downloadPdf();  // Start downloading the PDF when the widget is initialized
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text(widget.title),
      ),
      child: SafeArea(
        child: loading
            ? Center(child: CupertinoActivityIndicator())  // Cupertino version of CircularProgressIndicator
            : localPath != null
            ? PDFView(
          filePath: localPath,  // Provide the local path to the PDF
        )
            : Center(child: Text("Error loading PDF")),
      ),
    );
  }
}
