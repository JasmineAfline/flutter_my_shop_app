import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FAQScreen extends StatelessWidget {
  static const String routeName = '/faq';
  
  const FAQScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'FAQ',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('faqs')
            .orderBy('order', descending: false)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return _buildDefaultFAQs(context);
          }
          
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              final data = snapshot.data!.docs[index].data() as Map<String, dynamic>;
              return _FAQItem(
                question: data['question'] ?? '',
                answer: data['answer'] ?? '',
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildDefaultFAQs(BuildContext context) {
    final faqs = [
      {
        'question': 'How do I place an order?',
        'answer': 'Browse our products, add items to your cart, and proceed to checkout. You can pay using M-Pesa for a seamless experience.',
      },
      {
        'question': 'What payment methods do you accept?',
        'answer': 'We currently accept M-Pesa payments through STK Push. Simply enter your phone number during checkout to receive the payment prompt.',
      },
      {
        'question': 'How long does delivery take?',
        'answer': 'Delivery typically takes 2-5 business days within Kenya. You will receive tracking information once your order is shipped.',
      },
      {
        'question': 'Can I return a product?',
        'answer': 'Yes, we accept returns within 7 days of delivery for unused items in original packaging. Contact our support for return instructions.',
      },
      {
        'question': 'How do I track my order?',
        'answer': 'Go to your Profile > Recent Orders to view the status of your orders. You can also contact our support for detailed tracking information.',
      },
      {
        'question': 'Is my personal information secure?',
        'answer': 'Yes, we take data privacy seriously. Your information is encrypted and stored securely. We never share your data with third parties.',
      },
      {
        'question': 'How do I contact customer support?',
        'answer': 'You can reach us through the Messages section in your profile, or email us at support@myshop.com.',
      },
      {
        'question': 'Do you offer wholesale pricing?',
        'answer': 'Yes, we offer wholesale pricing for bulk orders. Please contact our sales team through the Messages section for custom quotes.',
      },
    ];

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: faqs.length,
      itemBuilder: (context, index) {
        return _FAQItem(
          question: faqs[index]['question']!,
          answer: faqs[index]['answer']!,
        );
      },
    );
  }
}

class _FAQItem extends StatefulWidget {
  final String question;
  final String answer;

  const _FAQItem({
    required this.question,
    required this.answer,
  });

  @override
  State<_FAQItem> createState() => _FAQItemState();
}

class _FAQItemState extends State<_FAQItem> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        leading: Icon(
          _isExpanded ? Icons.help : Icons.help_outline,
          color: _isExpanded ? Theme.of(context).primaryColor : Colors.grey,
        ),
        title: Text(
          widget.question,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 15,
            color: _isExpanded ? Theme.of(context).primaryColor : null,
          ),
        ),
        onExpansionChanged: (expanded) {
          setState(() => _isExpanded = expanded);
        },
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Text(
              widget.answer,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade700,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
