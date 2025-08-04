import 'package:flutter/material.dart';

class OptionCard extends StatelessWidget {
  final String title;
  final String title2;
  final String icon;
  final bool active;
  final int id;
  final Function onClick;
  const OptionCard(
      {Key key,
      @required this.title,
      @required this.title2,
      @required this.icon,
      @required this.id,
      @required this.onClick,
      this.active = false})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => this.onClick(this.id),
      child: Card(
        elevation: 3.0,
        color: this.active ? Theme.of(context).primaryColor : Colors.white,
        shadowColor:
            this.active ? Theme.of(context).accentColor : Color(0xFFf7f7f7),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10.0),
        ),
        child: Container(
          width: ((MediaQuery.of(context).size.width - 80) / 3).floorToDouble(),
          height: 100,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                margin: EdgeInsets.fromLTRB(5.0, 5.0, 5.0, 10.0),
                child: Image.asset("$icon"),
              ),
              Text(
                "$title",
                style: Theme.of(context).textTheme.bodyText1,
              ),
              Text(
                "$title2",
                style: Theme.of(context).textTheme.bodyText1,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
