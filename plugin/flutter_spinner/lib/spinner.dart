
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter_spinner/size_layout_delegate.dart';

typedef SpinnerListBuilder = Widget Function(BuildContext context,SpinnerState state);

typedef SpinnerBarBuilder = Widget Function(BuildContext context, Animation<double> animation);

class Spinner extends StatefulWidget{
  final int id;
  //部件高度
  final double height;
  //列表长度最小显示，最大上限
  final double min,max;
  //列表距离顶部距离
  final double posY;
  final Color borderColor;
  final Color color;
  final double opacity;
  final StreamController<int> controller;
  final SpinnerListBuilder spinnerListBuilder;
  final AlignmentGeometry alignment;
  final NavigatorState navigatorState;
  final EdgeInsetsGeometry padding;
  final SpinnerBarBuilder spinnerBarBuilder;

  Spinner({
    Key key,
    this.id,
    this.height,
    this.min = 0.0,
    this.max = 200.0,
    this.posY = 0.0,
    this.alignment,
    this.navigatorState,
    this.color = const Color(0xCC424242),
    this.borderColor,
    this.opacity = 1.0,
    this.padding,
    this.controller,
    @required this.spinnerBarBuilder,
    @required this.spinnerListBuilder
  }) : assert(min > 0),assert(height > 0),super(key : key);

  createState() => SpinnerState();
}

class SpinnerState extends State<Spinner> with TickerProviderStateMixin{
  Offset _pos;
  int _playStatus = -1;
  List<OverlayEntry> _overlayEntryList = [];
  GlobalKey _key = GlobalKey();
  Offset _currentPos;
  double _width = 0;
  AnimationController _controller;
  Animation<double> _icTurn,_posAnimation;
  Function _listener,_statusListener;
  Animation<Color> _borderColor,_bgColor;
  DateTime _firstClickTime;
  Size _bodySize;
  final Animatable<double> _easeTween = CurveTween(curve: Curves.ease),
      _halfTween = Tween<double>(begin: 0.0, end: 0.5);
  ColorTween _bgColorTween,_borderColorTween;
  final Duration _duration = const Duration(milliseconds: 300);

  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_width == 0){
        RenderBox renderBox = _key.currentContext.findRenderObject();
        _width = renderBox.size.width;
      }
    });
    widget?.controller?.stream?.listen((id) {
      if (id + 1 == widget.id)
        handleTap();
    });
    super.initState();
    _controller = AnimationController(duration: _duration, vsync: this);
    _icTurn = _controller.drive(_halfTween.chain(_easeTween));

    if (null != widget.borderColor){
      _borderColorTween = ColorTween();
      _borderColorTween.begin = Colors.transparent;
      _borderColorTween.end = widget.borderColor;
      _borderColor = _controller.drive(_borderColorTween.chain(_easeTween));
    }

    _bgColorTween = ColorTween();
    _bgColorTween.begin = Colors.transparent;
    _bgColorTween.end = widget.color.withOpacity(widget.opacity);
    _bgColor = _controller.drive(_bgColorTween.chain(_easeTween));

    _controller.value = 1.0;
    _listener = () => setState(() {});
    _statusListener = (status){
      if (status == AnimationStatus.dismissed)
        close();
    };
    _controller.addListener(_listener);
    _controller.addStatusListener(_statusListener);
  }

  OverlayState get overlay => null == widget.navigatorState ? Overlay.of(context) : widget.navigatorState.overlay;

  @override
  Widget build(BuildContext context) {
    Widget currentBox = Listener(
        behavior: HitTestBehavior.opaque,
        onPointerDown: (event) {
          handleTap();
        },
        child: Align(
            key: _key,
            alignment: widget.alignment,
            child: widget.spinnerBarBuilder(context, _icTurn)
        )
    );
    final bool switchColor = _icTurn.value == 0.5;
    final Color color = switchColor ? Colors.transparent : _bgColor.value;
    currentBox = Container(
        height: widget.height,
        decoration: null == widget.borderColor ? BoxDecoration(
          color: color,
        ) : BoxDecoration(
            color: color,
            border: Border.all(color: switchColor ? Colors.transparent : _borderColor?.value,width: 0.5)
        ),
        child: currentBox);
    if (null != widget.padding)
      currentBox = Padding(padding: widget.padding, child: currentBox);
    return currentBox;
  }

  handleTap(){
    if (-1 != _linkageId)
      return;
    if(_firstClickTime == null){
      _firstClickTime = DateTime.now();
    }else if(DateTime.now().difference(_firstClickTime) < _duration){
      _firstClickTime = DateTime.now();
      return;
    }
    RenderBox renderBox = _key.currentContext.findRenderObject();
    _currentPos = renderBox.localToGlobal(Offset.zero);
    _pos = Offset(_currentPos.dx,_currentPos.dy+renderBox.size.height+widget.posY);
    _playStatus == 0 ? _handlerShrink() : _handlerDistend();
  }

  _handlerDistend(){
    int length = _overlayEntryList.length;
    if (length > 0){
      int len = length - 1;
      for (int i = len; i > -1; --i) {
        _overlayEntryList[i]?.remove();
        _overlayEntryList.removeAt(i);
      }
    }
    _controller?.forward();
    _playStatus = 0;
    _overlayEntryList.addAll([
      overlayEntryBg,
      overlayEntryList
    ]);
    overlay.insertAll(_overlayEntryList);
    if (mounted)
      setState(() {});
  }

  _handlerShrink(){
    _controller?.reverse();
    _playStatus = 1;
    _overlayEntryList[1] = overlayEntryList;
    overlay.rearrange(_overlayEntryList);
    if (mounted)
      setState(() {});
  }

  int _linkageId = -1;

  OverlayEntry get overlayEntryBg => OverlayEntry(builder: (context) => Listener(
      child: Material(color: Colors.transparent),
      behavior: HitTestBehavior.opaque,
      onPointerDown: (event) {
        if (_linkageId != -1)
          return;
        if (null != widget.id){
          double dx = event.localPosition.dx;
          double dy = event.localPosition.dy;
          int id = dx ~/ _width;
          if (widget.id != id && dy >= _currentPos.dy && dy <= _pos.dy){
            _linkageId = id;
            _handlerShrink();
            return;
          }
        }
        handleTap();
      }
  ));

  OverlayEntry get overlayEntryList => OverlayEntry(builder: (context) {
    _bodySize = Size(_width, widget.min > widget.max ? widget.max : widget.min);
    if (_oldMinHeight == null){
      _oldMinHeight = _bodySize.height;
      Tween<double> _posTween = Tween<double>(begin: 0.0, end: _oldMinHeight);
      _posAnimation = _controller.drive(_posTween.chain(_easeTween));
    }
    return buildBody();
  });

  close(){
    _playStatus = -1;
    if (-1 != _linkageId){
      widget?.controller?.sink?.add(_linkageId-1);
      _linkageId = -1;
    }
  }

  double _oldMinHeight;

  Widget buildBody() {
    if (_oldMinHeight != _bodySize.height){
      Tween<double> _posTween = Tween<double>(begin: 0.0, end: _bodySize.height);
      _posAnimation = _controller.drive(_posTween.chain(_easeTween));
      _oldMinHeight = _bodySize.height;
    }
    if (-1 != _playStatus)
      _playStatus == 0 ? _controller?.forward() : _controller?.reverse();
    return Positioned(
        top: _pos.dy,
        left: _pos.dx,
        child: AnimatedBuilder(
            animation: _posAnimation,
            builder: (context, _) {
              return CustomSingleChildLayout(
                  delegate: SizeLayoutDelegate(Size(_bodySize.width,_posAnimation.value)),
                  child: widget.spinnerListBuilder(context,this)
              );
            })
    );
  }

  @override
  void didUpdateWidget(covariant Spinner oldWidget) {
    if (widget != oldWidget){
      _controller?.removeListener(_listener);
      _controller?.addListener(_listener);
      _controller?.removeStatusListener(_statusListener);
      _controller?.addStatusListener(_statusListener);
    }
    super.didUpdateWidget(oldWidget);
  }

  @override
  void dispose() {
    _controller?.removeListener(_listener);
    _controller?.removeStatusListener(_statusListener);
    _controller?.dispose();
    _listener = null;
    _statusListener = null;
    _controller = null;
    _posAnimation = null;
    super.dispose();
  }
}