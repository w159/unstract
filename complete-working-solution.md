# Unstract Platform - Current Status and Issues

## Critical Issues Found

### 1. Frontend Image Pull Error

- The ACR registry `acrunstract21468.azurecr.io` is returning 401 Unauthorized
- The image `unstract/frontend:latest` either doesn't exist or the credentials are invalid
- This is preventing the React frontend from deploying

### 2. Authentication Works But Limited

- Login endpoint works: `POST /api/v1/login` with `unstract/unstract`
- Session is created successfully
- But organization context is not being set properly

### 3. API Routes Issue

- All API endpoints return 401 Unauthorized
- The `/mock_org/users` page returns 404 because the frontend isn't serving the React app
- The nginx proxy is working but there's no React application to serve

## What IS Working

1. ✅ Backend API (Django) - Running and responding
2. ✅ PostgreSQL Database - Has all tables and data
3. ✅ Redis Cache - Running
4. ✅ MinIO Object Storage - Running
5. ✅ RabbitMQ Message Queue - Running
6. ✅ Platform Service - Running with all env vars
7. ✅ X2Text Service - Running and healthy
8. ✅ Prompt Service - Running
9. ✅ Runner Service - Running
10. ✅ Login Authentication - Works via API

## What is NOT Working

1. ❌ Frontend React App - Cannot pull image from ACR
2. ❌ User Management Page - 404 because no React app
3. ❌ Document Upload - Frontend needed to access this
4. ❌ Profile Editing - Frontend needed to access this

## Root Cause

The Azure Container Registry (ACR) that hosts the Unstract images is not accessible. Either:

1. The ACR credentials in the `acr-secret` are expired/invalid
2. The images were removed from the registry
3. The registry itself is no longer accessible

## Immediate Solutions

### Option 1: Use Docker Hub Images (if available)

Replace ACR images with Docker Hub equivalents if they exist.

### Option 2: Build Frontend Locally

Build the frontend from source code and push to a accessible registry.

### Option 3: Use Pre-built Static Files

If you have the built React app, we can serve it with nginx.

## The Real Problem

Without access to the original container images, particularly the frontend image that contains the built React application, we cannot fully restore the UI functionality. The backend is working perfectly, but users can't interact with it without the frontend.
