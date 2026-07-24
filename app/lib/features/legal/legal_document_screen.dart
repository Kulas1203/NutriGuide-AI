import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/design/components.dart';
import '../../core/design/tokens.dart';

/// Renders a bundled legal/policy markdown document.
///
/// Documents are drafts requiring legal review before publication and use
/// clearly labeled placeholders for owner-specific details (master
/// requirement §20). A lightweight renderer keeps us free of unmaintained
/// markdown dependencies.
class LegalDocumentScreen extends StatelessWidget {
  const LegalDocumentScreen({super.key, required this.document});

  final String document;

  static const _titles = {
    'privacy': 'Privacy Policy',
    'terms': 'Terms of Service',
    'disclaimer': 'Wellness & Medical Disclaimer',
    'ai-transparency': 'AI Transparency Notice',
    'acceptable-use': 'Acceptable Use Policy',
    'data-retention': 'Data Retention Policy',
    'account-deletion': 'Account Deletion',
    'support': 'Support & Complaints',
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_titles[document] ?? 'Document')),
      body: FutureBuilder<String>(
        future: rootBundle.loadString('assets/legal/$document.md'),
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const _LoadingDoc();
          }
          if (snapshot.hasError || !snapshot.hasData) {
            return const ErrorState(
              message: 'This document could not be loaded.',
            );
          }
          return SingleChildScrollView(
            padding: const EdgeInsets.all(NGSpacing.lg),
            child: _MarkdownView(snapshot.data!),
          );
        },
      ),
    );
  }
}

class _LoadingDoc extends StatelessWidget {
  const _LoadingDoc();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(NGSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SkeletonBox(height: 28, width: 200),
          SizedBox(height: NGSpacing.lg),
          SkeletonBox(height: 14),
          SizedBox(height: NGSpacing.sm),
          SkeletonBox(height: 14),
          SizedBox(height: NGSpacing.sm),
          SkeletonBox(height: 14, width: 260),
        ],
      ),
    );
  }
}

/// Minimal markdown renderer supporting headings (#, ##, ###), bullets (-),
/// bold (**text**) and paragraphs. Sufficient for our policy documents.
class _MarkdownView extends StatelessWidget {
  const _MarkdownView(this.source);

  final String source;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final widgets = <Widget>[];
    for (final rawLine in source.split('\n')) {
      final line = rawLine.trimRight();
      if (line.isEmpty) {
        widgets.add(const SizedBox(height: NGSpacing.sm));
      } else if (line.startsWith('### ')) {
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(
              top: NGSpacing.md,
              bottom: NGSpacing.xs,
            ),
            child: Text(line.substring(4), style: theme.textTheme.titleSmall),
          ),
        );
      } else if (line.startsWith('## ')) {
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(
              top: NGSpacing.lg,
              bottom: NGSpacing.sm,
            ),
            child: Text(line.substring(3), style: theme.textTheme.titleMedium),
          ),
        );
      } else if (line.startsWith('# ')) {
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(bottom: NGSpacing.sm),
            child: Text(
              line.substring(2),
              style: theme.textTheme.headlineSmall,
            ),
          ),
        );
      } else if (line.startsWith('- ')) {
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(
              bottom: NGSpacing.xs,
              left: NGSpacing.sm,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('•  '),
                Expanded(child: _rich(context, line.substring(2))),
              ],
            ),
          ),
        );
      } else if (line.startsWith('> ')) {
        widgets.add(
          Container(
            margin: const EdgeInsets.symmetric(vertical: NGSpacing.xs),
            padding: const EdgeInsets.all(NGSpacing.md),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainer,
              borderRadius: NGRadius.control,
            ),
            child: _rich(context, line.substring(2)),
          ),
        );
      } else {
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(bottom: NGSpacing.xs),
            child: _rich(context, line),
          ),
        );
      }
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: widgets,
    );
  }

  Widget _rich(BuildContext context, String text) {
    final theme = Theme.of(context);
    final spans = <TextSpan>[];
    final pattern = RegExp(r'\*\*(.+?)\*\*');
    var index = 0;
    for (final match in pattern.allMatches(text)) {
      if (match.start > index) {
        spans.add(TextSpan(text: text.substring(index, match.start)));
      }
      spans.add(
        TextSpan(
          text: match.group(1),
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
      );
      index = match.end;
    }
    if (index < text.length) {
      spans.add(TextSpan(text: text.substring(index)));
    }
    return RichText(
      text: TextSpan(style: theme.textTheme.bodyMedium, children: spans),
    );
  }
}
