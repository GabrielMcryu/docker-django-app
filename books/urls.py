from django.urls import path
from .views import BookListCreateView
from . import views

urlpatterns = [
    path('books/', BookListCreateView.as_view(), name='book-list-create'),
    path('redis-test/', views.test_redis, name='redis-test'),
]