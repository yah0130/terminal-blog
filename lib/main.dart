import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'utils/terminal_colors.dart';
import 'providers/terminal_state.dart';

void main() {
  runApp(const TerminalBlogApp());
}

class TerminalBlogApp extends StatelessWidget {
  const TerminalBlogApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => TerminalState(),
      child: MaterialApp(
        title: 'Terminal Blog',
        debugShowCheckedModeBanner: false,
        theme: ThemeData.dark().copyWith(
          scaffoldBackgroundColor: TermColors.bg,
        ),
        home: const TerminalWindow(),
      ),
    );
  }
}

class TerminalWindow extends StatefulWidget {
  const TerminalWindow({super.key});

  @override
  State<TerminalWindow> createState() => _TerminalWindowState();
}

class _TerminalWindowState extends State<TerminalWindow> {
  final TextEditingController _inputController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();
  bool _isUserScrolling = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.isScrollingNotifier.value) {
      _isUserScrolling = true;
    }
  }

  @override
  void dispose() {
    _inputController.dispose();
    _focusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _submitCommand() {
    final input = _inputController.text;
    if (input.isNotEmpty) {
      context.read<TerminalState>().executeCommand(input);
      _inputController.clear();
    }
    _isUserScrolling = false;
    _focusNode.requestFocus();
    _scrollToBottom();
  }

  void _navigateHistory(bool up) {
    final state = context.read<TerminalState>();
    state.navigateHistory(up);
    final cmd = state.historyCommand;
    if (cmd != null) {
      _inputController.text = cmd;
      _inputController.selection = TextSelection.fromPosition(
        TextPosition(offset: cmd.length),
      );
    }
  }

  void _scrollToBottom() {
    if (_isUserScrolling) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 100),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        margin: const EdgeInsets.all(40),
        decoration: BoxDecoration(
          color: TermColors.bg,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.5),
              blurRadius: 20,
              spreadRadius: 5,
            ),
          ],
        ),
        child: Column(
          children: [
            // Title bar
            Container(
              height: 40,
              decoration: const BoxDecoration(
                color: TermColors.titleBar,
                borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
              ),
              child: Row(
                children: [
                  const SizedBox(width: 16),
                  // Terminal buttons
                  _buildTerminalBtn(TermColors.closeBtn),
                  const SizedBox(width: 8),
                  _buildTerminalBtn(TermColors.minBtn),
                  const SizedBox(width: 8),
                  _buildTerminalBtn(TermColors.maxBtn),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Center(
                      child: Text(
                        'visitor@blog: ~/terminal-blog',
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 13,
                          color: Colors.white70,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 60),
                ],
              ),
            ),
            // Content area
            Expanded(
              child: Container(
                decoration: const BoxDecoration(
                  color: TermColors.contentBg,
                  border: Border(
                    left: BorderSide(color: TermColors.border, width: 1),
                    right: BorderSide(color: TermColors.border, width: 1),
                    bottom: BorderSide(color: TermColors.border, width: 1),
                  ),
                ),
                child: Consumer<TerminalState>(
                  builder: (context, state, _) {
                    WidgetsBinding.instance
                        .addPostFrameCallback((_) => _scrollToBottom());
                    return Column(
                      children: [
                        // Output area
                        Expanded(
                          child: ListView.builder(
                            controller: _scrollController,
                            padding: const EdgeInsets.all(16),
                            itemCount: state.outputHistory.length,
                            itemBuilder: (context, index) {
                              final line = state.outputHistory[index];
                              return Text(
                                line.text,
                                style: GoogleFonts.jetBrainsMono(
                                  fontSize: 14,
                                  height: 1.5,
                                  color: line.color ?? TermColors.command,
                                  fontWeight: line.fontWeight,
                                ),
                              );
                            },
                          ),
                        ),
                        // Input area
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: const BoxDecoration(
                            border: Border(
                              top: BorderSide(
                                  color: TermColors.border, width: 1),
                            ),
                          ),
                          child: Focus(
                            onKeyEvent: (node, event) {
                              if (event is KeyDownEvent) {
                                if (event.logicalKey ==
                                    LogicalKeyboardKey.arrowUp) {
                                  _navigateHistory(true);
                                  return KeyEventResult.handled;
                                }
                                if (event.logicalKey ==
                                    LogicalKeyboardKey.arrowDown) {
                                  _navigateHistory(false);
                                  return KeyEventResult.handled;
                                }
                              }
                              return KeyEventResult.ignored;
                            },
                            child: Row(
                              children: [
                                Text(
                                  '${state.promptPrefix}@blog:~\$ ',
                                  style: GoogleFonts.jetBrainsMono(
                                    fontSize: 14,
                                    color: TermColors.prompt,
                                  ),
                                ),
                                Expanded(
                                  child: TextField(
                                    controller: _inputController,
                                    focusNode: _focusNode,
                                    autofocus: true,
                                    style: GoogleFonts.jetBrainsMono(
                                      fontSize: 14,
                                      color: TermColors.command,
                                    ),
                                    cursorColor: TermColors.prompt,
                                    decoration: const InputDecoration(
                                      border: InputBorder.none,
                                      hintText: '',
                                    ),
                                    onSubmitted: (_) => _submitCommand(),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTerminalBtn(Color color) {
    return Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }
}
