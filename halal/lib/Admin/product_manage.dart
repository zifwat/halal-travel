import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

class ProductManage extends StatefulWidget {
  const ProductManage({Key? key}) : super(key: key);

  @override
  _ProductManageState createState() => _ProductManageState();
}

class _ProductManageState extends State<ProductManage> {
  late TextEditingController _searchController;
  late TextEditingController _barcodeController;
  late TextEditingController _productNameController;
  late TextEditingController _ingredientsController;
  late TextEditingController _statusController;
  late TextEditingController _categoryController;
  File? _productImage;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _barcodeController = TextEditingController();
    _productNameController = TextEditingController();
    _ingredientsController = TextEditingController();
    _statusController = TextEditingController();
    _categoryController = TextEditingController();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _barcodeController.dispose();
    _productNameController.dispose();
    _ingredientsController.dispose();
    _statusController.dispose();
    _categoryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ThemeData theme = ThemeData.dark();

    return Theme(
      data: theme.copyWith(
        primaryColor: Colors.black,
        scaffoldBackgroundColor: Colors.black,
        cardColor: Colors.grey[900],
        textTheme: theme.textTheme.copyWith(
          bodyText1: TextStyle(color: const Color.fromARGB(255, 128, 125, 125)),
          bodyText2: TextStyle(color: Colors.white),
        ),
      ),
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'Product Management',
            style: TextStyle(color: Colors.green),
          ),
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: _searchController,
                onChanged: (value) {
                  setState(() {});
                },
                decoration: InputDecoration(
                  labelText: 'Search Product',
                  filled: true,
                  fillColor: Color.fromARGB(255, 75, 71, 71),
                  prefixIcon: Icon(
                    Icons.search,
                    color: Colors.white,
                  ),
                  labelStyle: TextStyle(
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 16.0),
              ElevatedButton.icon(
                onPressed: () {
                  _showAddProductForm(context);
                },
                icon: Icon(Icons.add),
                label: Text('Add Product'),
                style: ElevatedButton.styleFrom(
                  primary: Colors.green,
                ),
              ),
              const SizedBox(height: 24.0),
              Expanded(
                child: ProductList(
                  productNameFilter: _searchController.text,
                  manageState: this,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _selectImage() async {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(Icons.photo_library),
                title: Text('Choose from Gallery'),
                onTap: () async {
                  Navigator.of(context).pop();
                  final picker = ImagePicker();
                  final pickedFile =
                      await picker.pickImage(source: ImageSource.gallery);
                  if (pickedFile != null) {
                    setState(() {
                      _productImage = File(pickedFile.path);
                    });
                  }
                },
              ),
              ListTile(
                leading: Icon(Icons.camera_alt),
                title: Text('Take a Picture'),
                onTap: () async {
                  Navigator.of(context).pop();
                  final picker = ImagePicker();
                  final pickedFile =
                      await picker.pickImage(source: ImageSource.camera);
                  if (pickedFile != null) {
                    setState(() {
                      _productImage = File(pickedFile.path);
                    });
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showAddProductForm(BuildContext context) {
    _barcodeController.clear();
    _productNameController.clear();
    _ingredientsController.clear();
    _statusController.clear();
    _categoryController.clear();
    setState(() {
      _productImage = null;
    });

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Add Product'),
          content: SingleChildScrollView(
            child: Column(
              children: [
                TextFormField(
                  controller: _barcodeController,
                  decoration: InputDecoration(
                    labelText: 'Barcode',
                  ),
                ),
                TextFormField(
                  controller: _productNameController,
                  decoration: InputDecoration(
                    labelText: 'Product Name',
                  ),
                ),
                TextFormField(
                  controller: _ingredientsController,
                  decoration: InputDecoration(
                    labelText: 'Ingredients',
                  ),
                ),
                TextFormField(
                  controller: _statusController,
                  decoration: InputDecoration(
                    labelText: 'Status',
                  ),
                ),
                TextFormField(
                  controller: _categoryController,
                  decoration: InputDecoration(
                    labelText: 'Category',
                  ),
                ),
                const SizedBox(height: 10),
                ElevatedButton.icon(
                  onPressed: _selectImage,
                  icon: Icon(Icons.image),
                  label: Text('Select Image'),
                  style: ElevatedButton.styleFrom(
                    primary: Colors.green,
                  ),
                ),
                if (_productImage != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Image.file(
                      _productImage!,
                      height: 100,
                    ),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                addProduct();
                Navigator.of(context).pop();
              },
              style: ElevatedButton.styleFrom(
                primary: Colors.green,
              ),
              child: Text('Add'),
            ),
          ],
        );
      },
    );
  }

  Future<void> addProduct() async {
    String barcode = _barcodeController.text;
    String productName = _productNameController.text;
    String ingredients = _ingredientsController.text;
    String status = _statusController.text;
    String category = _categoryController.text;

    String? imageUrl;
    if (_productImage != null) {
      imageUrl = await _uploadProductImage(_productImage!);
    }

    FirebaseFirestore.instance.collection('products').doc(barcode).set({
      'productName': productName,
      'ingredients': ingredients,
      'status': status,
      'category': category,
      if (imageUrl != null) 'imageUrl': imageUrl,
    });

    _barcodeController.clear();
    _productNameController.clear();
    _ingredientsController.clear();
    _statusController.clear();
    _categoryController.clear();
    setState(() {
      _productImage = null;
    });
  }

  Future<String> _uploadProductImage(File imageFile) async {
    String fileName = DateTime.now().millisecondsSinceEpoch.toString();
    Reference storageReference =
        FirebaseStorage.instance.ref().child('product_images/$fileName');
    UploadTask uploadTask = storageReference.putFile(imageFile);
    TaskSnapshot taskSnapshot = await uploadTask;
    return await taskSnapshot.ref.getDownloadURL();
  }

  Future<void> editProduct(DocumentSnapshot product) async {
    var data = product.data() as Map<String, dynamic>;
    _barcodeController.text = product.id;
    _productNameController.text = data['productName'];
    _ingredientsController.text = data['ingredients'];
    _statusController.text = data['status'];
    _categoryController.text = data['category'];
    setState(() {
      _productImage = null;
    });

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Edit Product'),
          content: SingleChildScrollView(
            child: Column(
              children: [
                TextFormField(
                  controller: _barcodeController,
                  decoration: InputDecoration(
                    labelText: 'Barcode',
                  ),
                  readOnly: true,
                ),
                TextFormField(
                  controller: _productNameController,
                  decoration: InputDecoration(
                    labelText: 'Product Name',
                  ),
                ),
                TextFormField(
                  controller: _ingredientsController,
                  decoration: InputDecoration(
                    labelText: 'Ingredients',
                  ),
                ),
                TextFormField(
                  controller: _statusController,
                  decoration: InputDecoration(
                    labelText: 'Status',
                  ),
                ),
                TextFormField(
                  controller: _categoryController,
                  decoration: InputDecoration(
                    labelText: 'Category',
                  ),
                ),
                const SizedBox(height: 10),
                ElevatedButton.icon(
                  onPressed: _selectImage,
                  icon: Icon(Icons.image),
                  label: Text('Select Image'),
                  style: ElevatedButton.styleFrom(
                    primary: Colors.green,
                  ),
                ),
                if (_productImage != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Image.file(
                      _productImage!,
                      height: 100,
                    ),
                  ),
                if (_productImage == null && data['imageUrl'] != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Image.network(
                      data['imageUrl'],
                      height: 100,
                    ),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _clearForm();
              },
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                String productName = _productNameController.text;
                String ingredients = _ingredientsController.text;
                String status = _statusController.text;
                String category = _categoryController.text;
                String? imageUrl = data['imageUrl'];

                if (_productImage != null) {
                  imageUrl = await _uploadProductImage(_productImage!);
                }

                FirebaseFirestore.instance
                    .collection('products')
                    .doc(product.id)
                    .update({
                  'productName': productName,
                  'ingredients': ingredients,
                  'status': status,
                  'category': category,
                  'imageUrl': imageUrl,
                });

                Navigator.of(context).pop();
                _clearForm();
              },
              style: ElevatedButton.styleFrom(
                primary: Colors.green,
              ),
              child: Text('Save'),
            ),
          ],
        );
      },
    );
  }

  Future<void> deleteProduct(
      BuildContext context, DocumentSnapshot product) async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Confirm Delete'),
          content: Text('Are you sure you want to delete this product?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();
                var data = product.data() as Map<String, dynamic>;
                String? imageUrl = data['imageUrl'];

                if (imageUrl != null) {
                  Reference storageReference =
                      FirebaseStorage.instance.refFromURL(imageUrl);
                  await storageReference.delete();
                }

                FirebaseFirestore.instance
                    .collection('products')
                    .doc(product.id)
                    .delete();
              },
              style: ElevatedButton.styleFrom(
                primary: Colors.red,
              ),
              child: Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  void _clearForm() {
    _barcodeController.clear();
    _productNameController.clear();
    _ingredientsController.clear();
    _statusController.clear();
    _categoryController.clear();
    setState(() {
      _productImage = null;
    });
  }
}

class ProductList extends StatelessWidget {
  final String productNameFilter;
  final _ProductManageState manageState;

  const ProductList(
      {Key? key, required this.productNameFilter, required this.manageState})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('products').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: CircularProgressIndicator(),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Text('Error: ${snapshot.error}'),
          );
        }

        var products = snapshot.data?.docs ?? [];

        if (productNameFilter.isNotEmpty) {
          products = products.where((product) {
            var data = product.data() as Map<String, dynamic>;
            return data['productName']
                .toLowerCase()
                .contains(productNameFilter.toLowerCase());
          }).toList();
        }

        return ListView.builder(
          itemCount: products.length,
          itemBuilder: (context, index) {
            var product = products[index];
            var data = product.data() as Map<String, dynamic>;

            return Card(
              elevation: 3.0,
              margin: const EdgeInsets.symmetric(vertical: 8.0),
              child: ListTile(
                leading: data['imageUrl'] != null
                    ? Image.network(
                        data['imageUrl'],
                        width: 50,
                        height: 50,
                        fit: BoxFit.cover,
                      )
                    : null,
                title: Text(
                  data['productName'],
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Ingredients: ${data['ingredients']}'),
                    Text('Status: ${data['status']}'),
                    Text('Category: ${data['category']}'),
                  ],
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(Icons.edit, color: Colors.blue),
                      onPressed: () {
                        manageState.editProduct(product);
                      },
                    ),
                    IconButton(
                      icon: Icon(Icons.delete, color: Colors.red),
                      onPressed: () {
                        manageState.deleteProduct(context, product);
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
