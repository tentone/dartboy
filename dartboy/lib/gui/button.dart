import 'package:flutter/material.dart';

/// Button widget with up and down callbacks.
class Button extends StatefulWidget
{
  /// Callback method executed when the button is pressed.
  Function onPressed;

  /// Callback method executed on the button is released.
  Function onReleased;

  /// Color of the button
  Color color;

  /// Label
  String label;

  Button({this.label, this.color, this.onPressed, this.onReleased, Key key}) : super(key: key);

  ButtonState createState()
  {
    return new ButtonState();
  }
}

class ButtonState extends State<Button>
{
  /// Indicates if the user is tapping the button.
  bool pressed = false;

  ButtonState();

  @override
  Widget build(BuildContext context)
  {
    return new Container
    (
      padding: const EdgeInsets.only(left: 0.0),
      child: new InkWell
      (
        enableFeedback: true,
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        onTapDown: (TapDownDetails details)
        {
          /*if(this.widget.onPressed != null)
          {
            this.widget.onPressed();
          }

          this.setState(()
          {
            this.pressed = true;
          });*/
        },
        onHighlightChanged: (bool highlight)
        {
          if(!this.pressed && highlight && this.widget.onPressed != null)
          {
            this.widget.onPressed();
          }

          if(this.pressed && !highlight && this.widget.onReleased != null)
          {
            this.widget.onReleased();
          }

          this.pressed = highlight;
          this.setState((){});
        },
        onTapCancel: ()
        {
          /*if(this.widget.onReleased != null)
          {
            this.widget.onReleased();
          }

          this.setState(()
          {
            this.pressed = false;
          });*/
        },
        onTap: (){},
        child: new Row
        (
          crossAxisAlignment: CrossAxisAlignment.center,
          children:
          [
            new Container
            (
              height: 50.0,
              width: 50.0,
              decoration: new BoxDecoration
              (
                color: this.pressed ? Colors.grey : this.widget.color,
                borderRadius: new BorderRadius.circular(20.0)

              ),
              child: new Center(child: new Text(this.widget.label, style: const TextStyle(color: Colors.white),))
            )
          ]
        )
      )
    );
  }
}