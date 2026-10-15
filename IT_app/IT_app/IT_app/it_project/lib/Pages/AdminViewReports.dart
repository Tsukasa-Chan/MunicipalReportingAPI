import 'package:flutter/material.dart'; // Gives you access to widgets such as scaffold, text etc.
import 'login.dart';
import 'Help.dart';

class AdminViewPage extends StatefulWidget {
  const AdminViewPage({super.key});

  @override
  State<AdminViewPage> createState() => _AdminViewPageState();
}

class _AdminViewPageState extends State<AdminViewPage> {
  // SAMPLE DATA
  final reports = [
    {
      "id": "001",
      "issue": "Pothole",
      "addInfo":
          "There are multiple potholes on this road, on the oncoming lanes as well",
      "location": "20 Dolphin Road",
      "date": "17/05/2026",
      "status": "Pending",
    },
    {
      "id": "002",
      "issue": "Broken Street Light",
      "addInfo": "",
      "location": "50 King Shaka Road",
      "date": "02/07/2026",
      "status": "Pending",
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: Image.asset(
                'lib/img/app logo.png',
                width: 42,
                height: 42,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              "View Reports",
              style: TextStyle(color: Colors.white, fontSize: 30),
            ),
          ],
        ),
        centerTitle: true,
        backgroundColor: Colors.red,

        leading: GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    const LoginPage(), // CHANGE LOGIN PAGE TO HOME PAGE
              ),
            );
          },
        ),
      ),

      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: reports.length,
              itemBuilder: (context, index) {
                return ExpansionTile(
                  title: Text(
                    "Report #${reports[index]["id"]}",
                  ), // Report number
                  children: [
                    Row(
                      children: [
                        Text("Report Status: ", style: TextStyle(fontSize: 32)),
                        Text(
                          reports[index]["status"] ??
                              "No status", // SAMPLE DATA
                          style: TextStyle(color: Colors.orange, fontSize: 32),
                        ),
                      ],
                    ),

                    SizedBox(height: 30),

                    Text("Date Submitted: ", style: TextStyle(fontSize: 20)),
                    Text(
                      reports[index]["date"] ?? "No date", // SAMPLE DATA
                    ),
                    SizedBox(height: 25),

                    Text("Type of Issue: ", style: TextStyle(fontSize: 20)),
                    Text(
                      reports[index]["issue"]!, // SAMPLE DATA
                    ),
                    SizedBox(height: 25), // Leaves spaces in between text

                    Text("Location of Issue: ", style: TextStyle(fontSize: 20)),
                    Text(
                      reports[index]["location"]!, // SAMPLE DATA
                    ),
                    SizedBox(height: 25),

                    Text(
                      "Additional Information: ",
                      style: TextStyle(fontSize: 20),
                    ),
                    Text(
                      reports[index]["addInfo"] ??
                          "No Additional Information", // SAMPLE DATA
                      style: TextStyle(fontSize: 15),
                    ),
                    SizedBox(height: 25),

                    Text("Image: ", style: TextStyle(fontSize: 20)),

                    ElevatedButton(
                      onPressed: () {
                        //Allow for admin to submit a picture AND change status from pending to solved
                      },
                      child: Text(
                        'Add Image',
                        style: TextStyle(color: Colors.black),
                      ),
                    ),

                    ElevatedButton(
                      onPressed: () {
                        //Allow for admin to submit a picture AND change status from pending to solved
                      },
                      child: Text(
                        'Change Status',
                        style: TextStyle(color: Colors.black),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 1,
        backgroundColor: Colors.red,
        selectedItemColor: Colors.white,
        onTap: (index) {
          if (index == 1) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const HelpPage(), //Navigates to help page
              ),
            );
          }
        },

        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.map), // built in icons
            label: 'Map',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.help), label: 'Help'),
        ],
      ),
    );
  }
}
