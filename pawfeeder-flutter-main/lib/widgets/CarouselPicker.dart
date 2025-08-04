import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';

class CarouselPicker extends StatelessWidget {
  final List<String> values;
  final Function onSelect;
  final int defaultPosition;
  const CarouselPicker({
    Key key,
    @required this.values,
    @required this.onSelect,
    @required this.defaultPosition,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: MediaQuery.of(context).size.width,
        child: CarouselSelect(
          onChanged: (selectedValue) {
            this.onSelect(selectedValue);
          },
          valueList: this.values,
          backgroundColor:
              Theme.of(context).textTheme.bodyText2.color.withOpacity(0.1),
          activeItemTextColor: Theme.of(context).textTheme.bodyText1.color,
          passiveItemsTextColor:
              Theme.of(context).textTheme.bodyText2.color.withOpacity(0.5),
          initialPosition: defaultPosition,
          scrollDirection: ScrollDirection.horizontal,
          activeItemFontSize: 15.0,
          passiveItemFontSize: 14.0,
          height: 50.0,
        ),
      ),
    );
  }
}
