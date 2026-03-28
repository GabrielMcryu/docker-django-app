from django.core.cache import cache
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework.decorators import api_view
from rest_framework import status
from .models import Book
from .serializers import BookSerializer

class BookListCreateView(APIView):
    def get(self, request):
        books = Book.objects.all()
        serializer = BookSerializer(books, many=True)
        return Response(serializer.data)

    def post(self, request):
        serializer = BookSerializer(data=request.data)
        if serializer.is_valid():
            serializer.save()
            return Response(serializer.data, status=status.HTTP_201_CREATED)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

@api_view(['GET'])
def test_redis(request):
    try:
        cache.set('redis_test', 'redis is connected!', timeout=30)
        value = cache.get('redis_test')
        return Response({'status': 'success', 'message': value})
    except Exception as e:
        return Response({'status': 'error', 'message': str(e)}, status=500)