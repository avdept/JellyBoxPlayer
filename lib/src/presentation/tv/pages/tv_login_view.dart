import 'dart:async';

import 'package:flutter/material.dart';
import 'package:jplayer/src/presentation/pages/login_page.dart';
import 'package:jplayer/src/presentation/tv/tv_tokens.dart';
import 'package:jplayer/src/presentation/tv/widgets/widgets.dart';
import 'package:jplayer/src/presentation/widgets/login_logo.dart';

class TvLoginView extends StatelessWidget {
  const TvLoginView({required this.state, super.key});

  final LoginPageState state;

  @override
  Widget build(BuildContext context) {
    final error = state.error;
    final theme = Theme.of(context);

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 80, vertical: 40),
        child: Row(
          children: [
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  LoginLogo(
                    serverType: state.resolvedServerType,
                    productName: state.serverProductName,
                  ),
                  const SizedBox(height: 28),
                  const Text(
                    'Sign in to your music server',
                    style: TvTokens.title,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    state.quickConnectAvailable
                        ? 'Quick Connect lets you approve this TV from a '
                              'phone or computer where you are already signed '
                              'in, so you do not have to type a password with '
                              'the remote.'
                        : 'Enter your server address and account details '
                              'with the remote.',
                    style: TvTokens.body.copyWith(color: Colors.white70),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 60),
            SizedBox(
              width: 380,
              child: Center(
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _serverField(context),
                      const SizedBox(height: 14),
                      TvTextField(
                        label: 'Login',
                        controller: state.loginController,
                        keyboardType: TextInputType.text,
                        textInputAction: TextInputAction.next,
                      ),
                      const SizedBox(height: 14),
                      TvTextField(
                        label: 'Password',
                        controller: state.passwordController,
                        obscureText: true,
                        keyboardType: TextInputType.visiblePassword,
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) => unawaited(state.signIn()),
                      ),
                      if (error != null) ...[
                        const SizedBox(height: 12),
                        Text(
                          error,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: theme.colorScheme.error,
                          ),
                        ),
                      ],
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(
                            child: TvButton(
                              label: 'Sign in',
                              primary: true,
                              onSelect: () => unawaited(state.signIn()),
                            ),
                          ),
                          if (state.quickConnectAvailable) ...[
                            const SizedBox(width: 12),
                            Expanded(
                              child: TvButton(
                                label: 'Quick Connect',
                                icon: Icons.phonelink_rounded,
                                onSelect: () =>
                                    unawaited(state.signInWithQuickConnect()),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _serverField(BuildContext context) {
    final server = state.selectedServer;
    if (server == null) {
      return TvTextField(
        label: 'Server URL',
        controller: state.serverUrlController,
        focusNode: state.serverUrlFocusNode,
        keyboardType: TextInputType.url,
        textInputAction: TextInputAction.next,
        autofocus: true,
        suffix: state.serverResolved
            ? Icon(
                Icons.check_circle,
                color: Theme.of(context).colorScheme.secondary,
                size: 22,
              )
            : null,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Server',
          style: TextStyle(fontSize: 13, color: Colors.white70),
        ),
        const SizedBox(height: 6),
        TvFocusable(
          onSelect: state.editSelectedServer,
          autofocus: true,
          scrollOnFocus: false,
          debugLabel: 'server:${server.name}',
          builder: (context, focused) => AnimatedContainer(
            duration: TvTokens.focusDuration,
            curve: TvTokens.focusCurve,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: focused ? 0.16 : 0.08),
              borderRadius: TvTokens.cardRadius,
              border: Border.all(
                color: focused ? TvTokens.focusRing : Colors.transparent,
                width: 2,
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.dns_outlined, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        server.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 15),
                      ),
                      Text(
                        server.serverUrl,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TvTokens.caption,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                const Text('Edit', style: TvTokens.caption),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
